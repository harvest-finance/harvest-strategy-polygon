//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../../strategies/balancer/interface/IBVault.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract VaultMigratable_balStMatic is Vault {
  using SafeERC20 for IERC20;

  address public constant __wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public constant __stmatic = address(0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4);
  address public constant __lpOld = address(0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D);
  address public constant __lpNew = address(0x8159462d255C1D24915CB51ec361F700174cD994);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
  address public constant __bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant __newStrategy = address(0x9674AdE8257BEeC0f8c6fbdEAE279EA92543D989);

  bytes32 public constant __poolIdOld = 0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366;
  bytes32 public constant __poolIdNew = 0x8159462d255c1d24915cb51ec361f700174cd99400000000000000000000075d;

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountToken0, uint256 amountToken1);
  event LiquidityProvided(uint256 amountToken0, uint256 amountToken1, uint256 v2Liquidity);

  constructor() public {
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _balancerWithdraw(
    bytes32 poolId,
    uint256 amountIn,
    uint256[] memory minAmountsOut
  ) internal {
    (address[] memory poolTokens,,) = IBVault(__bVault).getPoolTokens(poolId);
    uint256 _nTokens = poolTokens.length;

    IAsset[] memory assets = new IAsset[](_nTokens);
    for (uint256 i = 0; i < _nTokens; i++) {
      assets[i] = IAsset(poolTokens[i]);
    }

    IBVault.ExitKind exitKind = IBVault.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT;
    bytes memory userData = abi.encode(exitKind, amountIn);

    IBVault.ExitPoolRequest memory request;
    request.assets = assets;
    request.minAmountsOut = minAmountsOut;
    request.userData = userData;

    IBVault(__bVault).exitPool(
      poolId,
      address(this),
      payable(address(this)),
      request
    );
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, __bVault, amountIn);
    IBVault(__bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  /**
  * Migrates the vault from the old MaticX BPT underlying to new MaticX BPT underlying
  */
  function migrateUnderlying(
    uint256 minWMaticOut,
    uint256 minStMaticOut,
    uint256 minLPNewOut
  ) public onlyControllerOrGovernance {
    require(underlying() == __lpOld, "Can only migrate if the underlying is 2JPY");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lpOld).balanceOf(address(this));
    console.log("V1Liquidity:     ", v1Liquidity);
    uint256[] memory minOutput = new uint256[](2);
    minOutput[0] = minWMaticOut;
    minOutput[1] = minStMaticOut;

    _balancerWithdraw(__poolIdOld, v1Liquidity, minOutput);
    uint256 amountWMatic = IERC20(__wmatic).balanceOf(address(this));
    uint256 amountStMatic = IERC20(__stmatic).balanceOf(address(this));
    console.log("WMatic out:      ", amountWMatic);
    console.log("stMatic out:     ", amountStMatic);

    emit LiquidityRemoved(v1Liquidity, amountWMatic, amountStMatic);

    require(IERC20(__lpOld).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _balancerSwap(__wmatic, __lpNew, __poolIdNew, amountWMatic, 1);
    _balancerSwap(__stmatic, __lpNew, __poolIdNew, amountStMatic, 1);
    uint256 v2Liquidity = IERC20(__lpNew).balanceOf(address(this));
    require(v2Liquidity >= minLPNewOut, "Output amount too low");
    console.log("V2Liquidity:     ", v2Liquidity);

    emit LiquidityProvided(amountWMatic, amountStMatic, v2Liquidity);

    _setUnderlying(__lpNew);
    require(underlying() == __lpNew, "underlying switch failed");
    console.log("New underlying:  ", underlying());
    _setStrategy(__newStrategy);
    require(strategy() == __newStrategy, "strategy switch failed");
    console.log("New strategy:    ", strategy());

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 wMaticLeft = IERC20(__wmatic).balanceOf(address(this));
    if (wMaticLeft > 0) {
      IERC20(__wmatic).transfer(strategy(), wMaticLeft);
    }
    uint256 stMaticLeft = IERC20(__stmatic).balanceOf(address(this));
    if (stMaticLeft > 0) {
      IERC20(__stmatic).transfer(__governance, stMaticLeft);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

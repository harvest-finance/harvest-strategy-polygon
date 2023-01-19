//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../../strategies/balancer/interface/IBVault.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract VaultMigratable_balMaticX is Vault {
  using SafeERC20 for IERC20;

  address public constant __wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public constant __maticx = address(0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6);
  address public constant __lpOld = address(0xC17636e36398602dd37Bb5d1B3a9008c7629005f);
  address public constant __lpNew = address(0xb20fC01D21A50d2C734C4a1262B4404d41fA7BF0);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
  address public constant __bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant __newStrategy = address(0x5A42FEDdD5e330AD857A17724543C5ef7FC7C9Cd);

  bytes32 public constant __poolIdOld = 0xc17636e36398602dd37bb5d1b3a9008c7629005f0002000000000000000004c4;
  bytes32 public constant __poolIdNew = 0xb20fc01d21a50d2c734c4a1262b4404d41fa7bf000000000000000000000075c;

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
    uint256 minMaticXOut,
    uint256 minLPNewOut
  ) public onlyControllerOrGovernance {
    require(underlying() == __lpOld, "Can only migrate if the underlying is 2JPY");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lpOld).balanceOf(address(this));
    console.log("V1Liquidity:     ", v1Liquidity);
    uint256[] memory minOutput = new uint256[](2);
    minOutput[0] = minWMaticOut;
    minOutput[1] = minMaticXOut;

    _balancerWithdraw(__poolIdOld, v1Liquidity, minOutput);
    uint256 amountWMatic = IERC20(__wmatic).balanceOf(address(this));
    uint256 amountMaticX = IERC20(__maticx).balanceOf(address(this));
    console.log("WMatic out:      ", amountWMatic);
    console.log("MaticX out:      ", amountMaticX);

    emit LiquidityRemoved(v1Liquidity, amountWMatic, amountMaticX);

    require(IERC20(__lpOld).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _balancerSwap(__wmatic, __lpNew, __poolIdNew, amountWMatic, 1);
    _balancerSwap(__maticx, __lpNew, __poolIdNew, amountMaticX, 1);
    uint256 v2Liquidity = IERC20(__lpNew).balanceOf(address(this));
    require(v2Liquidity >= minLPNewOut, "Output amount too low");
    console.log("V2Liquidity:     ", v2Liquidity);

    emit LiquidityProvided(amountWMatic, amountMaticX, v2Liquidity);

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
    uint256 maticXLeft = IERC20(__maticx).balanceOf(address(this));
    if (maticXLeft > 0) {
      IERC20(__maticx).transfer(__governance, maticXLeft);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../interface/curve/ICurveDeposit_2token.sol";
import "../../strategies/balancer/interface/IBVault.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

contract VaultMigratable_bal2EUR_PAR is Vault {
  using SafeERC20 for IERC20;

  address public constant __token0 = address(0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c);
  address public constant __token1 = address(0xE2Aa7db6dA1dAE97C5f5C6914d285fBfCC32A128);
  address public constant __lpOld = address(0x0f110c55EfE62c16D553A3d3464B77e1853d0e97);
  address public constant __lpNew = address(0x7d60a4Cb5cA92E2Da965637025122296ea6854f9);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
  address public constant __bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant __newStrategy = address(0x222E14Dc2f82d1d903e539C39B0C578B7353be7E);

  bytes32 public constant __poolIdNew = 0x7d60a4cb5ca92e2da965637025122296ea6854f900000000000000000000085e;

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
  * Migrates the vault from the old Curve LP underlying to new Balancer LP underlying
  */
  function migrateUnderlying(
    uint256 minToken0Out,
    uint256 minToken1Out,
    uint256 minLPNewOut
  ) public onlyControllerOrGovernance {
    require(underlying() == __lpOld, "Can only migrate if the underlying is lpOld");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__lpOld).balanceOf(address(this));
    console.log("V1Liquidity:     ", v1Liquidity);

    ICurveDeposit_2token(__lpOld).remove_liquidity(v1Liquidity, [minToken0Out, minToken1Out]);
    uint256 amount0 = IERC20(__token0).balanceOf(address(this));
    uint256 amount1 = IERC20(__token1).balanceOf(address(this));
    console.log("token0 out:      ", amount0);
    console.log("token1 out:      ", amount1);

    emit LiquidityRemoved(v1Liquidity, amount0, amount1);

    require(IERC20(__lpOld).balanceOf(address(this)) == 0, "Not all underlying was converted");

    _balancerSwap(__token0, __lpNew, __poolIdNew, amount0, 1);
    _balancerSwap(__token1, __lpNew, __poolIdNew, amount1, 1);
    uint256 v2Liquidity = IERC20(__lpNew).balanceOf(address(this));
    require(v2Liquidity >= minLPNewOut, "Output amount too low");
    console.log("V2Liquidity:     ", v2Liquidity);

    emit LiquidityProvided(amount0, amount1, v2Liquidity);

    _setUnderlying(__lpNew);
    require(underlying() == __lpNew, "underlying switch failed");
    console.log("New underlying:  ", underlying());
    _setStrategy(__newStrategy);
    require(strategy() == __newStrategy, "strategy switch failed");
    console.log("New strategy:    ", strategy());

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 token0Left = IERC20(__token0).balanceOf(address(this));
    if (token0Left > 0) {
      IERC20(__token0).transfer(strategy(), token0Left);
    }
    uint256 token1Left = IERC20(__token1).balanceOf(address(this));
    if (token1Left > 0) {
      IERC20(__token1).transfer(__governance, token1Left);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

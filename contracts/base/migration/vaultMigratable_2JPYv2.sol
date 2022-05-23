//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../Vault.sol";
import "../interface/curve/ICurveDeposit_2token.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "hardhat/console.sol";

interface IJPYCSwap {
  function swap() external;
}

contract VaultMigratable_2JPYv2 is Vault {
  using SafeERC20 for IERC20;

  address public constant __jjpy = address(0x8343091F2499FD4b6174A46D067A920a3b851FF9);
  address public constant __jpyc = address(0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c);
  address public constant __jpycv2 = address(0x431D5dfF03120AFA4bDf332c61A6e1766eF37BDB);
  address public constant __2jpy = address(0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A);
  address public constant __2jpyv2 = address(0xaA91CDD7abb47F821Cf07a2d38Cc8668DEAf1bdc);
  address public constant __2jpyv2_strategy = address(0x45257F1c56bE3D381f49371b47c3EEb1E8358431);
  address public constant __governance = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);

  address public constant __jpyc_swap = address(0x382d78E8BcEa98fA04b63C19Fe97D8138C3bfC5D);

  event Migrated(uint256 v1Liquidity, uint256 v2Liquidity);
  event LiquidityRemoved(uint256 v1Liquidity, uint256 amountJJPY, uint256 amountJPYC);
  event LiquidityProvided(uint256 JPYCv2Contributed, uint256 JJPYContributed, uint256 v2Liquidity);

  constructor() public {
  }

  /**
  * Migrates the vault from the 2JPY underlying to 2JPYv2 underlying
  */
  function migrateUnderlying(
    uint256 minJJPYOut, uint256 minJPYCOut,
    uint256 min2JPYv2Mint
  ) public onlyControllerOrGovernance {
    require(underlying() == __2jpy, "Can only migrate if the underlying is 2JPY");
    withdrawAll();

    uint256 v1Liquidity = IERC20(__2jpy).balanceOf(address(this));

    ICurveDeposit_2token(__2jpy).remove_liquidity(v1Liquidity, [minJJPYOut, minJPYCOut]);
    uint256 amountJJPY = IERC20(__jjpy).balanceOf(address(this));
    uint256 amountJPYC = IERC20(__jpyc).balanceOf(address(this));

    emit LiquidityRemoved(v1Liquidity, amountJJPY, amountJPYC);

    require(IERC20(__2jpy).balanceOf(address(this)) == 0, "Not all underlying was converted");

    IERC20(__jpyc).safeApprove(__jpyc_swap, 0);
    IERC20(__jpyc).safeApprove(__jpyc_swap, uint256(-1));
    IJPYCSwap(__jpyc_swap).swap();
    uint256 jpycv2Balance = IERC20(__jpycv2).balanceOf(address(this));

    IERC20(__jpycv2).safeApprove(__2jpyv2, 0);
    IERC20(__jpycv2).safeApprove(__2jpyv2, jpycv2Balance);
    IERC20(__jjpy).safeApprove(__2jpyv2, 0);
    IERC20(__jjpy).safeApprove(__2jpyv2, amountJJPY);

    ICurveDeposit_2token(__2jpyv2).add_liquidity([amountJJPY, jpycv2Balance], min2JPYv2Mint);
    uint256 v2Liquidity = IERC20(__2jpyv2).balanceOf(address(this));

    emit LiquidityProvided(jpycv2Balance, amountJJPY, v2Liquidity);

    _setUnderlying(__2jpyv2);
    require(underlying() == __2jpyv2, "underlying switch failed");
    _setStrategy(__2jpyv2_strategy);
    require(strategy() == __2jpyv2_strategy, "strategy switch failed");

    // some steps that regular setStrategy does
    IERC20(underlying()).safeApprove(address(strategy()), 0);
    IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));

    uint256 jjpyLeft = IERC20(__jjpy).balanceOf(address(this));
    if (jjpyLeft > 0) {
      IERC20(__jjpy).transfer(__governance, jjpyLeft);
    }
    uint256 jpycv2Left = IERC20(__jpycv2).balanceOf(address(this));
    if (jpycv2Left > 0) {
      IERC20(__jpycv2).transfer(strategy(), jpycv2Left);
    }

    emit Migrated(v1Liquidity, v2Liquidity);
  }
}

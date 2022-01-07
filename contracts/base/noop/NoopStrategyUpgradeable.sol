//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";

contract NoopStrategyUpgradeable is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  constructor() public BaseUpgradeableStrategy() {}

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault
  ) public initializer {

    require(_vault != address(0), "_vault cannot be empty");
    require(_underlying == IVault(_vault).underlying(), "underlying mismatch");

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      address(0),
      address(0),
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function investedUnderlyingBalance() external view returns (uint256 balance) {
      balance = IERC20(underlying()).balanceOf(address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() external restricted {
    if (IERC20(underlying()).balanceOf(address(this)) > 0) {
      IERC20(underlying()).safeTransfer(address(vault()), IERC20(underlying()).balanceOf(address(this)));
    }
  }

  /*
  * Cashes some amount out and withdraws to the vault
  */
  function withdrawToVault(uint256 amount) external restricted {
    require(IERC20(underlying()).balanceOf(address(this)) >= amount,
      "insufficient balance for the withdrawal");
    if (amount > 0) {
      IERC20(underlying()).safeTransfer(address(vault()), amount);
    }
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  * Honest harvesting. It's not much, but it pays off
  */
  function doHardWork() external restricted {
    // a no-op
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

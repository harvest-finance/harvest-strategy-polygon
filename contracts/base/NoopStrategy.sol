//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interface/IStrategy.sol";
import "./inheritance/Controllable.sol";
import "./interface/IVault.sol";


contract NoopStrategy is IStrategy, Controllable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public override underlying;
  address public override vault;

  // These tokens cannot be claimed by the controller
  mapping(address => bool) public override unsalvagableTokens;

  bool public withdrawAllCalled = false;

  constructor(address _storage, address _underlying, address _vault) public
  Controllable(_storage) {
    require(_underlying != address(0), "_underlying cannot be empty");
    require(_vault != address(0), "_vault cannot be empty");
    underlying = _underlying;
    vault = _vault;
  }

  function depositArbCheck() public override view returns(bool) {
    return true;
  }

  modifier restricted() {
    require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
      "The sender has to be the controller or vault or governance");
    _;
  }

  /*
  * Returns the total invested amount.
  */
  function investedUnderlyingBalance() public override view returns (uint256) {
    // for real strategies, need to calculate the invested balance
    return IERC20(underlying).balanceOf(address(this));
  }

  /*
  * Invests all tokens that were accumulated so far
  */
  function investAllUnderlying() public {
  }

  /*
  * Cashes everything out and withdraws to the vault
  */
  function withdrawAllToVault() external override restricted {
    withdrawAllCalled = true;
    if (IERC20(underlying).balanceOf(address(this)) > 0) {
      IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
    }
  }

  /*
  * Cashes some amount out and withdraws to the vault
  */
  function withdrawToVault(uint256 amount) external override restricted {
    if (amount > 0) {
      IERC20(underlying).safeTransfer(vault, amount);
    }
  }

  /*
  * Honest harvesting. It's not much, but it pays off
  */
  function doHardWork() external override restricted {
    // a no-op
  }

  // should only be called by controller
  function salvage(address destination, address token, uint256 amount) external override onlyControllerOrGovernance {
    IERC20(token).safeTransfer(destination, amount);
  }
}

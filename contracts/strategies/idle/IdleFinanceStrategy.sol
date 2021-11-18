//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/inheritance/RewardTokenProfitNotifier.sol";
import "../../base/interface/IStrategy.sol";
import "../../base/interface/IVault.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "./interface/IdleToken.sol";

contract IdleFinanceStrategy is RewardTokenProfitNotifier {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(address);
  event Liquidating(address, uint256);

  address public referral;
  IERC20 public underlying;
  address public idleUnderlying;
  uint256 public virtualPrice;

  address public vault;

  address[] public rewardTokens;
  mapping(address => address[]) public reward2WETH;
  address[] public WETH2underlying;
  mapping(address => bool) public sell;
  mapping(address => bool) public useQuick;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

  bool public claimAllowed;
  bool public protected;

  // These tokens cannot be claimed by the controller
  mapping (address => bool) public unsalvagableTokens;

  modifier restricted() {
    require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
      "The sender has to be the controller or vault or governance");
    _;
  }

  modifier updateVirtualPrice() {
    if (protected) {
      require(virtualPrice <= IIdleTokenV3_1(idleUnderlying).tokenPriceWithFee(address(this)), "virtual price is higher than needed");
    }
    _;
    virtualPrice = IIdleTokenV3_1(idleUnderlying).tokenPriceWithFee(address(this));
  }

  constructor(
    address _storage,
    address _underlying,
    address _idleUnderlying,
    address _vault
  ) RewardTokenProfitNotifier(_storage, weth) public {
    underlying = IERC20(_underlying);
    idleUnderlying = _idleUnderlying;
    vault = _vault;
    protected = true;

    // set these tokens to be not salvagable
    unsalvagableTokens[_underlying] = true;
    unsalvagableTokens[_idleUnderlying] = true;
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      unsalvagableTokens[token] = true;
    }
    referral = address(0xf00dD244228F51547f0563e60bCa65a30FBF5f7f);
    claimAllowed = true;

    virtualPrice = IIdleTokenV3_1(idleUnderlying).tokenPriceWithFee(address(this));
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function setReferral(address _newRef) public onlyGovernance {
    referral = _newRef;
  }

  /**
  * The strategy invests by supplying the underlying token into IDLE.
  */
  function investAllUnderlying() public restricted updateVirtualPrice {
    uint256 balance = underlying.balanceOf(address(this));
    underlying.safeApprove(address(idleUnderlying), 0);
    underlying.safeApprove(address(idleUnderlying), balance);
    IIdleTokenV3_1(idleUnderlying).mintIdleToken(balance, true, referral);
  }

  /**
  * Exits IDLE and transfers everything to the vault.
  */
  function withdrawAllToVault() external restricted updateVirtualPrice {
    withdrawAll();
    IERC20(address(underlying)).safeTransfer(vault, underlying.balanceOf(address(this)));
  }

  /**
  * Withdraws all from IDLE
  */
  function withdrawAll() internal {
    uint256 balance = IERC20(idleUnderlying).balanceOf(address(this));
    uint256 underlyingBalanceInvested = balance.mul(virtualPrice).div(1e18);
    uint256 underlyingBalanceBefore = underlying.balanceOf(address(this));
    // this automatically claims the crops
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(balance);
    uint256 underlyingBalanceAfter = underlying.balanceOf(address(this));
    require(underlyingBalanceAfter >= (underlyingBalanceBefore + underlyingBalanceInvested), "withdrawal output too low");

    liquidateRewards();
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted {
    // this method is called when the vault is missing funds
    // we will calculate the proportion of idle LP tokens that matches
    // the underlying amount requested
    uint256 balanceBefore = underlying.balanceOf(address(this));
    uint256 totalIdleLpTokens = IERC20(idleUnderlying).balanceOf(address(this));
    uint256 totalUnderlyingBalance = totalIdleLpTokens.mul(virtualPrice).div(1e18);
    uint256 ratio = amountUnderlying.mul(1e18).div(totalUnderlyingBalance);
    uint256 toRedeem = totalIdleLpTokens.mul(ratio).div(1e18);
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(toRedeem);
    uint256 balanceAfter = underlying.balanceOf(address(this));
    require(balanceAfter >= (balanceBefore + amountUnderlying), "withdrawal output too low");
    underlying.safeTransfer(vault, balanceAfter.sub(balanceBefore));
  }

  /**
  * Withdraws all assets, liquidates COMP, and invests again in the required ratio.
  */
  function doHardWork() public restricted updateVirtualPrice {
    if (claimAllowed) {
      claim();
    }
    liquidateRewards();

    // this updates the virtual price
    investAllUnderlying();

    // state of supply/loan will be updated by the modifier
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function claim() internal {
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(0);
  }

  function liquidateRewards() internal {
    uint256 wethBalanceBeforeClaim = IERC20(weth).balanceOf(address(this));
    for (uint256 i=0;i<rewardTokens.length;i++) {
      address token = rewardTokens[i];
      if (!sell[token]) {
        // Profits can be disabled for possible simplified and rapid exit
        emit ProfitsNotCollected(token);
        continue;
      }
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance > 0) {
        emit Liquidating(token, balance);
        address routerV2;
        if(useQuick[token]) {
          routerV2 = quickswapRouterV2;
        } else {
          routerV2 = sushiswapRouterV2;
        }
        IERC20(token).safeApprove(routerV2, 0);
        IERC20(token).safeApprove(routerV2, balance);
        // we can accept 1 as the minimum because this will be called only by a trusted worker
        IUniswapV2Router02(routerV2).swapExactTokensForTokens(
          balance, 1, reward2WETH[token], address(this), block.timestamp
        );
      }
    }

    uint256 wethBalanceAfterClaim = IERC20(weth).balanceOf(address(this));
    notifyProfitInRewardToken(wethBalanceAfterClaim.sub(wethBalanceBeforeClaim));

    uint256 remainingWethBalance = IERC20(weth).balanceOf(address(this));

    if (remainingWethBalance > 0 && WETH2underlying.length > 1) {
      emit Liquidating(weth, remainingWethBalance);
      address routerV2;
      if(useQuick[address(underlying)]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(weth).safeApprove(routerV2, 0);
      IERC20(weth).safeApprove(routerV2, remainingWethBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        remainingWethBalance, 1, WETH2underlying, address(this), block.timestamp
      );
    }
  }

  /**
  * Returns the current balance. Ignores COMP that was not liquidated and invested.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // NOTE: The use of virtual price is okay for appreciating assets inside IDLE,
    // but would be wrong and exploitable if funds were lost by IDLE, indicated by
    // the virtualPrice being greater than the token price.
    if (protected) {
      require(virtualPrice <= IIdleTokenV3_1(idleUnderlying).tokenPriceWithFee(address(this)), "virtual price is higher than needed");
    }
    uint256 invested = IERC20(idleUnderlying).balanceOf(address(this)).mul(virtualPrice).div(1e18);
    return invested.add(IERC20(underlying).balanceOf(address(this)));
  }

  function setLiquidation(address _token, bool _sell) public onlyGovernance {
     sell[_token] = _sell;
  }

  function setClaimAllowed(bool _claimAllowed) public onlyGovernance {
    claimAllowed = _claimAllowed;
  }

  function setProtected(bool _protected) public onlyGovernance {
    protected = _protected;
  }
}

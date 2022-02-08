//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "../interface/uniswap/IUniswapV2Router02.sol";
import "./interface/IStakingDualRewards.sol";
import "./interface/IDragonLair.sol";
import "../interface/uniswap/IUniswapV2Pair.sol";

contract DualRewardsLPStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant dragonLair = address(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);
  address public constant quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  // this would be reset on each upgrade
  mapping (address => address[]) public BASE2deposit;
  mapping (address => address[]) public reward2BASE;
  mapping (address => bool) public useQuick;
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    bool _isQuickPair
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    address _lpt = IStakingDualRewards(rewardPool()).stakingToken();
    require(_lpt == underlying(), "StakingToken does not match underlying");
    if (_isQuickPair) {
      useQuick[underlying()] = true;
    }
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      bal = IStakingDualRewards(rewardPool()).balanceOf(address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
        IStakingDualRewards(rewardPool()).exit();
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IStakingDualRewards(rewardPool()).withdraw(bal);
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IStakingDualRewards(rewardPool()).stake(entireBalance);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setDepositLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[0] == rewardToken(), "Path should start with baseReward");
    address finalToken = _route[_route.length-1];
    address LPComponentToken0 = IUniswapV2Pair(underlying()).token0();
    address LPComponentToken1 = IUniswapV2Pair(underlying()).token1();
    require(finalToken == LPComponentToken0 || finalToken == LPComponentToken1, "Path should end with LP component");
    BASE2deposit[finalToken] = _route;
    useQuick[finalToken] = _useQuick;
  }

  function setRewardLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    address startToken = _route[0];
    address finalToken = _route[_route.length-1];
    require(finalToken == rewardToken(), "Path should end with baseReward");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (startToken == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2BASE[startToken] = _route;
    useQuick[startToken] = _useQuick;
  }

  /**
   * if the pool gets dQuick as reward token it has to first be converted to QUICK
   * by leaving the dragonLair
   */
  function convertDQuickToQuick() internal {
    uint256 dQuickBalance = IERC20(dragonLair).balanceOf(address(this));
    if (dQuickBalance > 0){
      IDragonLair(dragonLair).leave(dQuickBalance);
    }
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapoolId exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      if (token == quick){
        convertDQuickToQuick();
      }
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));
      if (rewardBalance == 0 || reward2BASE[token].length < 2) {
        continue;
      }

      address routerV2;
      if(useQuick[token]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(token).safeApprove(routerV2, 0);
      IERC20(token).safeApprove(routerV2, rewardBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        rewardBalance, 1, reward2BASE[token], address(this), block.timestamp
      );
    }

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address LPComponentToken0 = IUniswapV2Pair(underlying()).token0();
    address LPComponentToken1 = IUniswapV2Pair(underlying()).token1();
    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);
    uint256 token0Amount;
    uint256 token1Amount;
    uint256 amountOutMin = 1;

    if (BASE2deposit[LPComponentToken0].length > 1) {
      address routerV2;
      if(useQuick[LPComponentToken0]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(rewardToken()).safeApprove(routerV2, 0);
      IERC20(rewardToken()).safeApprove(routerV2, toToken0);
      // if we need to liquidate the token0
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        toToken0,
        amountOutMin,
        BASE2deposit[LPComponentToken0],
        address(this),
        block.timestamp
      );
      token0Amount = IERC20(LPComponentToken0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token0Amount = toToken0;
    }

    if (BASE2deposit[LPComponentToken1].length > 1) {
      address routerV2;
      if(useQuick[LPComponentToken1]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(rewardToken()).safeApprove(routerV2, 0);
      IERC20(rewardToken()).safeApprove(routerV2, toToken1);
      // sell reward token to token1
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        toToken1,
        amountOutMin,
        BASE2deposit[LPComponentToken1],
        address(this),
        block.timestamp
      );
      token1Amount = IERC20(LPComponentToken1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }
    address routerV2;
    if(useQuick[underlying()]) {
      routerV2 = quickswapRouterV2;
    } else {
      routerV2 = sushiswapRouterV2;
    }

    // provide token1 and token2 to SUSHI
    IERC20(LPComponentToken0).safeApprove(routerV2, 0);
    IERC20(LPComponentToken0).safeApprove(routerV2, token0Amount);

    IERC20(LPComponentToken1).safeApprove(routerV2, 0);
    IERC20(LPComponentToken1).safeApprove(routerV2, token1Amount);

    // we provide liquidity to sushi
    IUniswapV2Router02(routerV2).addLiquidity(
      LPComponentToken0,
      LPComponentToken1,
      token0Amount,
      token1Amount,
      1,  // we are willing to take whatever the pair gives us
      1,  // we are willing to take whatever the pair gives us
      address(this),
      block.timestamp
    );
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IStakingDualRewards(rewardPool()).withdraw(toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
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
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IStakingDualRewards(rewardPool()).getReward();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

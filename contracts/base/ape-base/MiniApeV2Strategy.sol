//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "./interface/IMiniChefV2.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";


contract MiniApeV2Strategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant apeswapRouterV2 = address(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _IS_LP_ASSET_SLOT = 0xc2f3dabf55b1bdda20d5cf5fcba9ba765dfc7c9dbaf28674ce46d43d60d58768;
  bytes32 internal constant _SECOND_REWARD_TOKEN_SLOT = 0xd06e5f1f8ce4bdaf44326772fc9785917d444f120d759a01f1f440e0a42d67a3;

  // this would be reset on each upgrade
  mapping (address => address[]) public uniswapRoutes;
  address[] public secondRewardRoute;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_IS_LP_ASSET_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.isLpAsset")) - 1));
    assert(_SECOND_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.secondRewardToken")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    address _secondRewardToken,
    uint256 _poolID,
    bool _isLpAsset
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

    IERC20 _lpt;
    _lpt = IMiniChefV2(rewardPool()).lpToken(_poolID);
    require(address(_lpt) == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolID);

    _setSecondRewardToken(_secondRewardToken);

    if (_isLpAsset) {
      address uniLPComponentToken0 = IUniswapV2Pair(underlying()).token0();
      address uniLPComponentToken1 = IUniswapV2Pair(underlying()).token1();

      // these would be required to be initialized separately by governance
      uniswapRoutes[uniLPComponentToken0] = new address[](0);
      uniswapRoutes[uniLPComponentToken1] = new address[](0);
    } else {
      uniswapRoutes[underlying()] = new address[](0);
    }

    setBoolean(_IS_LP_ASSET_SLOT, _isLpAsset);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMiniChefV2(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMiniChefV2(rewardPool()).withdrawAndHarvest(poolId(), bal, address(this));
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMiniChefV2(rewardPool()).emergencyWithdraw(poolId(), address(this));
      }
  }

  function harvestReward() internal {
      IMiniChefV2(rewardPool()).harvest(poolId(), address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IMiniChefV2(rewardPool()).deposit(poolId(), entireBalance, address(this));
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

  function setLiquidationPath(address _token, address [] memory _route) public onlyGovernance {
    uniswapRoutes[_token] = _route;
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    // swap second reward token to reward token
    uint256 secondRewardBalance = IERC20(secondRewardToken()).balanceOf(address(this));

    // allow Uniswap to sell our reward
    IERC20(secondRewardToken()).safeApprove(apeswapRouterV2, 0);
    IERC20(secondRewardToken()).safeApprove(apeswapRouterV2, secondRewardBalance);

    if (secondRewardBalance > 0) {
      IUniswapV2Router02(apeswapRouterV2).swapExactTokensForTokens(
        secondRewardBalance,
        amountOutMin,
        secondRewardRoute,
        address(this),
        block.timestamp
      );
    }

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    if (!sell() || rewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    // allow Uniswap to sell our reward
    IERC20(rewardToken()).safeApprove(apeswapRouterV2, 0);
    IERC20(rewardToken()).safeApprove(apeswapRouterV2, remainingRewardBalance);

    if (isLpAsset()) {
      address uniLPComponentToken0 = IUniswapV2Pair(underlying()).token0();
      address uniLPComponentToken1 = IUniswapV2Pair(underlying()).token1();

      uint256 toToken0 = remainingRewardBalance.div(2);
      uint256 toToken1 = remainingRewardBalance.sub(toToken0);

      uint256 token0Amount;

      if (uniswapRoutes[uniLPComponentToken0].length > 1) {
        // if we need to liquidate the token0
        IUniswapV2Router02(apeswapRouterV2).swapExactTokensForTokens(
          toToken0,
          amountOutMin,
          uniswapRoutes[uniLPComponentToken0],
          address(this),
          block.timestamp
        );
        token0Amount = IERC20(uniLPComponentToken0).balanceOf(address(this));
      } else {
        // otherwise we assme token0 is the reward token itself
        token0Amount = toToken0;
      }

      uint256 token1Amount;

      if (uniswapRoutes[uniLPComponentToken1].length > 1) {
        // sell reward token to token1
        IUniswapV2Router02(apeswapRouterV2).swapExactTokensForTokens(
          toToken1,
          amountOutMin,
          uniswapRoutes[uniLPComponentToken1],
          address(this),
          block.timestamp
        );
        token1Amount = IERC20(uniLPComponentToken1).balanceOf(address(this));
      } else {
        token1Amount = toToken1;
      }

      // provide token1 and token2 to ape
      IERC20(uniLPComponentToken0).safeApprove(apeswapRouterV2, 0);
      IERC20(uniLPComponentToken0).safeApprove(apeswapRouterV2, token0Amount);

      IERC20(uniLPComponentToken1).safeApprove(apeswapRouterV2, 0);
      IERC20(uniLPComponentToken1).safeApprove(apeswapRouterV2, token1Amount);

      // we provide liquidity to ape
      uint256 liquidity;
      (,,liquidity) = IUniswapV2Router02(apeswapRouterV2).addLiquidity(
        uniLPComponentToken0,
        uniLPComponentToken1,
        token0Amount,
        token1Amount,
        1,  // we are willing to take whatever the pair gives us
        1,  // we are willing to take whatever the pair gives us
        address(this),
        block.timestamp
      );
    } else {
      IUniswapV2Router02(apeswapRouterV2).swapExactTokensForTokens(
        remainingRewardBalance,
        amountOutMin,
        uniswapRoutes[underlying()],
        address(this),
        block.timestamp
      );
    }
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
      IMiniChefV2(rewardPool()).withdraw(poolId(), toWithdraw, address(this));
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
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    harvestReward();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
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

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  // complexRewarder second reward
  function _setSecondRewardToken(address _address) internal {
    setAddress(_SECOND_REWARD_TOKEN_SLOT, _address);
  }

  function secondRewardToken() public view returns (address) {
    return getAddress(_SECOND_REWARD_TOKEN_SLOT);
  }

  function isLpAsset() public view returns (bool) {
    return getBoolean(_IS_LP_ASSET_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
    // reset the liquidation paths
    // they need to be re-set manually
    if (isLpAsset()) {
      uniswapRoutes[IUniswapV2Pair(underlying()).token0()] = new address[](0);
      uniswapRoutes[IUniswapV2Pair(underlying()).token1()] = new address[](0);
    } else {
      uniswapRoutes[underlying()] = new address[](0);
    }
  }
}

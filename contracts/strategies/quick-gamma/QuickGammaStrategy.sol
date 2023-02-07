//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "./interface/IMasterChef.sol";
import "./interface/IHypervisor.sol";
import "./interface/IUniProxy.sol";
import "./interface/IDragonLair.sol";

contract QuickGammaStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickRouter = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant uniProxy = address(0x8C8f7D348A568553819C4DaD401Ba6A68fa65924);
  address public constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public constant dQuick = address(0x958d208Cdf087843e9AD98d23823d32E17d723A1);
  address public constant quick = address(0xB5C064F955D8e7F38fE0460C556a72987494eE17);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;

  // this would be reset on each upgrade
  mapping (address => mapping (address => address[])) public swapRoutes;
  mapping (address => mapping (address => address)) public routers;
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _poolID
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      WMATIC,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    address _lpt = IMasterChef(rewardPool()).lpToken(_poolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolID);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).withdraw(poolId(), bal, address(this));
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).emergencyWithdraw(poolId(), address(this));
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    address _rewardPool = rewardPool();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(_rewardPool, 0);
    IERC20(_underlying).safeApprove(_rewardPool, entireBalance);
    IMasterChef(_rewardPool).deposit(poolId(), entireBalance, address(this));
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

  function setDepositLiquidationPath(address [] memory _route, address _router) public onlyGovernance {
    address tokenIn = _route[0];
    address tokenOut = _route[_route.length-1];
    require(tokenIn == WMATIC, "Path should start with WMATIC");
    swapRoutes[tokenIn][tokenOut] = _route;
    routers[tokenIn][tokenOut] = _router;
  }

  function setRewardLiquidationPath(address [] memory _route, address _router) public onlyGovernance {
    address tokenIn = _route[0];
    address tokenOut = _route[_route.length-1];
    require(tokenOut == WMATIC, "Path should end with WMATIC");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (tokenIn == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    swapRoutes[tokenIn][tokenOut] = _route;
    routers[tokenIn][tokenOut] = _router;
  }

  function addRewardToken(address _token, address[] memory _path2WMATIC, address _router) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WMATIC, _router);
  }

  /**
   * if the pool gets dQuick as reward token it has to first be converted to QUICK
   * by leaving the dragonLair
   */
  function convertDQuickToQuick() internal {
    uint256 dQuickBalance = IERC20(dQuick).balanceOf(address(this));
    if (dQuickBalance > 0){
      IDragonLair(dQuick).leave(dQuickBalance);
    }
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      if (token == quick){
        convertDQuickToQuick();
      }
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if (swapRoutes[token][_rewardToken].length < 2 || rewardBalance == 0) {
        continue;
      }

      address router = routers[token][_rewardToken];
      IERC20(token).safeApprove(router, 0);
      IERC20(token).safeApprove(router, rewardBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(router).swapExactTokensForTokens(
        rewardBalance, 1, swapRoutes[token][_rewardToken], address(this), block.timestamp
      );
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance < 1e15) {
      return;
    }

    _depositToGamma();
  }

  function _depositToGamma() internal {
    address _underlying = underlying();
    address _token0 = IHypervisor(_underlying).token0();
    address _token1 = IHypervisor(_underlying).token1();
    (uint256 toToken0, uint256 toToken1) = _calculateToTokenAmounts();

    (uint256 amount0, uint256 amount1) = _swapToTokens(_token0, _token1, toToken0, toToken1);
    uint256[4] memory minIn = [uint(0), uint(0), uint(0), uint(0)];

    IERC20(_token0).safeApprove(_underlying, 0);
    IERC20(_token0).safeApprove(_underlying, amount0);
    IERC20(_token1).safeApprove(_underlying, 0);
    IERC20(_token1).safeApprove(_underlying, amount1);
    IUniProxy(uniProxy).deposit(amount0, amount1, address(this), _underlying, minIn);
  }

  function _calculateToTokenAmounts() internal view returns(uint256, uint256){
    address pool = underlying();
    (uint256 poolBalance0, uint256 poolBalance1) = IHypervisor(pool).getTotalAmounts();
    uint256 sqrtPrice0In1 = uint256(IUniProxy(uniProxy).getSqrtTwapX96(pool, 1));
    uint256 price0In1 = sqrtPrice0In1.mul(sqrtPrice0In1).div(uint(2**(96 * 2)).div(1e18));
    uint256 totalPoolBalanceIn1 = poolBalance0.mul(price0In1).div(1e18).add(poolBalance1);
    uint256 poolWeight0 = poolBalance0.mul(price0In1).div(totalPoolBalanceIn1);

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    uint256 toToken0 = rewardBalance.mul(poolWeight0).div(1e18);
    uint256 toToken1 = rewardBalance.sub(toToken0);
    return (toToken0, toToken1);
  }

  function _swapToTokens(
    address tokenOut0,
    address tokenOut1,
    uint256 toToken0,
    uint256 toToken1
  ) internal returns(uint256, uint256){
    address tokenIn = rewardToken();
    uint256 token0Amount;
    if (swapRoutes[tokenIn][tokenOut0].length > 1) {
      address router = routers[tokenIn][tokenOut0];
      // allow to sell our reward
      IERC20(tokenIn).safeApprove(router, 0);
      IERC20(tokenIn).safeApprove(router, toToken0);

      // if we need to liquidate the token0
      IUniswapV2Router02(router).swapExactTokensForTokens(
        toToken0,
        1,
        swapRoutes[tokenIn][tokenOut0],
        address(this),
        block.timestamp
      );
      token0Amount = IERC20(tokenOut0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (swapRoutes[tokenIn][tokenOut1].length > 1) {
      address router = routers[tokenIn][tokenOut1];
      // allow to sell our reward
      IERC20(tokenIn).safeApprove(router, 0);
      IERC20(tokenIn).safeApprove(router, toToken1);

      // if we need to liquidate the token0
      IUniswapV2Router02(router).swapExactTokensForTokens(
        toToken1,
        1,
        swapRoutes[tokenIn][tokenOut1],
        address(this),
        block.timestamp
      );
      token1Amount = IERC20(tokenOut1).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token1Amount = toToken1;
    }
    return (token0Amount, token1Amount);
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
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address _underlying = underlying();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IMasterChef(rewardPool()).withdraw(poolId(), toWithdraw, address(this));
    }

    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    address _underlying = underlying();
    if (rewardPool() == address(0)) {
      return IERC20(_underlying).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(_underlying).balanceOf(address(this)));
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
    IMasterChef(rewardPool()).withdraw(poolId(), 0, address(this));
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

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

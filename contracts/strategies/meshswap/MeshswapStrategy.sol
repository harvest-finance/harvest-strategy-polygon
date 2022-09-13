//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "./interface/IExchange.sol";
import "./interface/IRouter.sol";

contract MeshswapStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant meshRouter = address(0x10f4A785F458Bc144e3706575924889954946639);
  address public constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _TOKEN0_SLOT = 0x68243437d847411509893b84195df70ec4ea6f04c790e4d2129bda87e7c2ec78;
  bytes32 internal constant _TOKEN1_SLOT = 0xf68c08c14f3bdc68eaf979694faddc9d918df59c282e12dd8102cf1fc77248c0;

  // this would be reset on each upgrade
  mapping (address => mapping (address => address[])) public swapRoutes;
  mapping (address => mapping (address => address)) public routers;
  address[] public rewardTokens;


  constructor() public BaseUpgradeableStrategy() {
    assert(_TOKEN0_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.token0")) - 1));
    assert(_TOKEN1_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.token1")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      address(this),
      WMATIC,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      0, // sell floor
      12 hours // implementation change delay
    );

    address _token0 = IExchange(_underlying).token0();
    address _token1 = IExchange(_underlying).token1();
    _setToken0(_token0);
    _setToken1(_token1);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function underlyingBalance() internal view returns (uint256 balance) {
      balance = IERC20(underlying()).balanceOf(address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route, address _router) public onlyGovernance {
    address tokenIn = _route[0];
    address tokenOut = _route[_route.length-1];
    require(tokenIn == WMATIC, "Path should start with WMATIC");
    require(tokenOut == token0() || tokenOut == token1(), "Path should end with token0 or token1");
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

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if (swapRoutes[token][WMATIC].length < 2 || rewardBalance == 0) {
        continue;
      }

      address router = routers[token][WMATIC];
      IERC20(token).safeApprove(router, 0);
      IERC20(token).safeApprove(router, rewardBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(router).swapExactTokensForTokens(
        rewardBalance, 1, swapRoutes[token][WMATIC], address(this), block.timestamp
      );
    }

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _token0 = token0();
    address _token1 = token1();
    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    uint256 token0Amount;
    if (swapRoutes[WMATIC][_token0].length > 1) {
      address router = routers[WMATIC][_token0];
      // allow to sell our reward
      IERC20(rewardToken()).safeApprove(router, 0);
      IERC20(rewardToken()).safeApprove(router, toToken0);

      // if we need to liquidate the token0
      IUniswapV2Router02(router).swapExactTokensForTokens(
        toToken0,
        amountOutMin,
        swapRoutes[WMATIC][_token0],
        address(this),
        block.timestamp
      );
      token0Amount = IERC20(_token0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (swapRoutes[WMATIC][_token1].length > 1) {
      address router = routers[WMATIC][_token1];
      // allow to sell our reward
      IERC20(rewardToken()).safeApprove(router, 0);
      IERC20(rewardToken()).safeApprove(router, toToken1);

      // if we need to liquidate the token0
      IRouter(router).swapExactTokensForTokens(
        toToken1,
        amountOutMin,
        swapRoutes[WMATIC][_token1],
        address(this),
        block.timestamp
      );
      token1Amount = IERC20(_token1).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token1Amount = toToken1;
    }

    // provide token0 and token1 to MeshSwap
    IERC20(_token0).safeApprove(meshRouter, 0);
    IERC20(_token0).safeApprove(meshRouter, token0Amount);

    IERC20(_token1).safeApprove(meshRouter, 0);
    IERC20(_token1).safeApprove(meshRouter, token1Amount);

    // we provide liquidity to MeshSwap
    IUniswapV2Router02(meshRouter).addLiquidity(
      _token0,
      _token1,
      token0Amount,
      token1Amount,
      1,  // we are willing to take whatever the pair gives us
      1,  // we are willing to take whatever the pair gives us
      address(this),
      block.timestamp
    );
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    IExchange(_underlying).claimReward();
    _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if (amount >= entireBalance){
      withdrawAllToVault();
    } else {
      IERC20(_underlying).safeTransfer(vault(), amount);
    }
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return underlyingBalance();
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
    IExchange(underlying()).claimReward();
    _liquidateReward();
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

  function _setToken0(address _address) internal {
    setAddress(_TOKEN0_SLOT, _address);
  }

  function token0() public view returns (address) {
    return getAddress(_TOKEN0_SLOT);
  }

  function _setToken1(address _address) internal {
    setAddress(_TOKEN1_SLOT, _address);
  }

  function token1() public view returns (address) {
    return getAddress(_TOKEN1_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the receiving Matic
}

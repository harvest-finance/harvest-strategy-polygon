// SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./inheritance/Governable.sol";
import "./interface/IRewardPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FeeRewardForwarder is Governable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address constant public weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address constant public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);

  address constant public ifarm = address(0xab0b2ddB9C7e440fAc8E140A89c0dbCBf2d7Bbff);
  address constant public sushi = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
  address constant public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address constant public aave = address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);


  mapping (address => mapping (address => address[])) public routes;
  mapping (address => mapping (address => address[])) public routers;

  address constant public quickswapRouter = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address constant public sushiswapRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

  // the targeted reward token to convert everything to
  address public targetToken = weth;
  address public profitSharingPool;

  event TokenPoolSet(address token, address pool);

  constructor(address _storage) public Governable(_storage) {
    profitSharingPool = governance();

    routes[quick][weth] = [quick, weth];
    routers[quick][weth] = [quickswapRouter];

    routes[sushi][weth] = [sushi, weth];
    routers[sushi][weth] = [sushiswapRouter];

    routes[wmatic][weth] = [wmatic, weth];
    routers[wmatic][weth] = [quickswapRouter];
  }

  /*
  *   Set the pool that will receive the reward token
  *   based on the address of the reward Token
  */
  function setEOA(address _eoa) public onlyGovernance {
    profitSharingPool = _eoa;
    targetToken = weth;
    emit TokenPoolSet(targetToken, _eoa);
  }

  /**
  * Sets the path for swapping tokens to the to address
  * The to address is not validated to match the targetToken,
  * so that we could first update the paths, and then,
  * set the new target
  */
  function setConversionPath(address[] memory _route, address[] memory _routers)
    public
    onlyGovernance
  {
    require(
      _routers.length == 1 || _routers.length == _route.length-1,
      "Provide either 1 router in total, or 1 router per intermediate pair"
    );
    address from = _route[0];
    address to = _route[_route.length-1];
    routes[from][to] = _route;
    routers[from][to] = _routers;
  }

  // Transfers the funds from the msg.sender to the pool
  // under normal circumstances, msg.sender is the strategy
  function poolNotifyFixedTarget(address _token, uint256 _amount) external {
    uint256 remainingAmount = _amount;

    if (_token == weth) {
      // this is already the right token
      IERC20(_token).safeTransferFrom(msg.sender, profitSharingPool, _amount);
    } else {

      // we need to convert _token to WETH
      if (routes[_token][targetToken].length > 1) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), remainingAmount);
        uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));
        if (routers[_token][targetToken].length == 1) {
          liquidate(_token, targetToken, balanceToSwap);
        } else if (routers[_token][targetToken].length > 1) {
          liquidateMultiRouter(_token, targetToken, balanceToSwap);
        } else {
          revert("FeeRewardForwarder: liquidation routers not set");
        }

        // now we can send this token forward
        uint256 convertedRewardAmount = IERC20(targetToken).balanceOf(address(this));

        IERC20(targetToken).safeTransfer(profitSharingPool, convertedRewardAmount);
      } else {
        // else the route does not exist for this token
        // do not take any fees and revert.
        // It's better to set the liquidation path then perform it again,
        // rather then leaving the funds in controller
        revert("FeeRewardForwarder: liquidation path doesn't exist");
      }
    }
  }

  function liquidate(address _from, address _to, uint256 balanceToSwap) internal {
    if(balanceToSwap > 0){
      address router = routers[_from][_to][0];
      IERC20(_from).safeApprove(router, 0);
      IERC20(_from).safeApprove(router, balanceToSwap);

      IUniswapV2Router02(router).swapExactTokensForTokens(
        balanceToSwap,
        0,
        routes[_from][_to],
        address(this),
        block.timestamp
      );
    }
  }

  function liquidateMultiRouter(address _from, address _to, uint256 balanceToSwap) internal {
    if(balanceToSwap > 0){
      address[] memory _routers = routers[_from][_to];
      address[] memory _route = routes[_from][_to];
      for (uint256 i; i < _routers.length; i++ ) {
        address router = _routers[i];
        address[] memory route = new address[](2);
        route[0] = _route[i];
        route[1] = _route[i+1];
        uint256 amount = IERC20(route[0]).balanceOf(address(this));
        IERC20(route[0]).safeApprove(router, 0);
        IERC20(route[0]).safeApprove(router, amount);

        IUniswapV2Router02(router).swapExactTokensForTokens(
          amount,
          0,
          route,
          address(this),
          block.timestamp
        );
      }
    }
  }
}

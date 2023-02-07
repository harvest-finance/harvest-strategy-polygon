//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./QuickGammaStrategy.sol";

contract QuickGammaStrategyMainnet_USDC_ETH_wide is QuickGammaStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x6077177d4c41E114780D9901C9b5c784841C523f);
    address quick = address(0xB5C064F955D8e7F38fE0460C556a72987494eE17);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address masterChef = address(0x20ec0d06F447d550fC6edee42121bc8C1817b97D);
    QuickGammaStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      5
    );
    rewardTokens = [quick, WMATIC];
    swapRoutes[quick][WMATIC] = [quick, WMATIC];
    routers[quick][WMATIC] = quickRouter;
    swapRoutes[WMATIC][usdc] = [WMATIC, usdc];
    routers[WMATIC][usdc] = quickRouter;
    swapRoutes[WMATIC][weth] = [WMATIC, weth];
    routers[WMATIC][weth] = quickRouter;
  }
}
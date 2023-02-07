//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./QuickGammaStrategy.sol";

contract QuickGammaStrategyMainnet_MATIC_ETH_narrow is QuickGammaStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x02203f2351E7aC6aB5051205172D3f772db7D814);
    address quick = address(0xB5C064F955D8e7F38fE0460C556a72987494eE17);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address masterChef = address(0x20ec0d06F447d550fC6edee42121bc8C1817b97D);
    QuickGammaStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      0
    );
    rewardTokens = [quick, WMATIC];
    swapRoutes[quick][WMATIC] = [quick, WMATIC];
    routers[quick][WMATIC] = quickRouter;
    swapRoutes[WMATIC][weth] = [WMATIC, weth];
    routers[WMATIC][weth] = quickRouter;
  }
}

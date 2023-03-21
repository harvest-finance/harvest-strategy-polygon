//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./QuickGammaStrategy.sol";

contract QuickGammaStrategyMainnet_MATIC_USDC_wide is QuickGammaStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4A83253e88e77E8d518638974530d0cBbbF3b675);
    address quick = address(0xB5C064F955D8e7F38fE0460C556a72987494eE17);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address masterChef = address(0x20ec0d06F447d550fC6edee42121bc8C1817b97D);
    QuickGammaStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      3
    );
    rewardTokens = [quick, WMATIC];
    swapRoutes[quick][WMATIC] = [quick, WMATIC];
    routers[quick][WMATIC] = quickRouter;
    swapRoutes[WMATIC][usdc] = [WMATIC, usdc];
    routers[WMATIC][usdc] = quickRouter;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./MeshswapStrategy.sol";

contract MeshswapStrategyMainnet_WMATIC_USDC is MeshswapStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x6Ffe747579eD4E807Dec9B40dBA18D15226c32dC);
    address mesh = address(0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    MeshswapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
    rewardTokens = [mesh];
    swapRoutes[mesh][WMATIC] = [mesh, WMATIC];
    routers[mesh][WMATIC] = meshRouter;
    swapRoutes[WMATIC][usdc] = [WMATIC, usdc];
    routers[WMATIC][usdc] = meshRouter;
  }
}

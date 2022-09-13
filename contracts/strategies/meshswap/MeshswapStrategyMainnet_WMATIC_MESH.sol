//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./MeshswapStrategy.sol";

contract MeshswapStrategyMainnet_WMATIC_MESH is MeshswapStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x07A7Ab21b582058B71d2AEe1b1719926E3451ADF);
    address mesh = address(0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a);
    MeshswapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
    rewardTokens = [mesh];
    swapRoutes[mesh][WMATIC] = [mesh, WMATIC];
    routers[mesh][WMATIC] = meshRouter;
    swapRoutes[WMATIC][mesh] = [WMATIC, mesh];
    routers[WMATIC][mesh] = meshRouter;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./MeshswapStrategy.sol";

contract MeshswapStrategyMainnet_MESH_oMOOI is MeshswapStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5b1E475933C802117212ce2A4240A4e7999a52A2);
    address mesh = address(0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a);
    address oMooi = address(0x746351AB4B9d4f802B7b770f33184d0A6B17363D);
    MeshswapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
    rewardTokens = [oMooi];
    swapRoutes[oMooi][WMATIC] = [oMooi, WMATIC];
    routers[oMooi][WMATIC] = meshRouter;
    swapRoutes[WMATIC][mesh] = [WMATIC, mesh];
    routers[WMATIC][mesh] = meshRouter;
    swapRoutes[WMATIC][oMooi] = [WMATIC, oMooi];
    routers[WMATIC][oMooi] = meshRouter;
  }
}

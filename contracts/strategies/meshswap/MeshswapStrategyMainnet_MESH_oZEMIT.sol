//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./MeshswapStrategy.sol";

contract MeshswapStrategyMainnet_MESH_oZEMIT is MeshswapStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x6fC01D72960Af0De3dD97D544FE785b751D752E2);
    address mesh = address(0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a);
    address oZemit = address(0xA34E0eaCB7fbB0b0d45da89b083E0f87fcdf6157);
    MeshswapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
    rewardTokens = [oZemit];
    swapRoutes[oZemit][WMATIC] = [oZemit, WMATIC];
    routers[oZemit][WMATIC] = meshRouter;
    swapRoutes[WMATIC][mesh] = [WMATIC, mesh];
    routers[WMATIC][mesh] = meshRouter;
    swapRoutes[WMATIC][oZemit] = [WMATIC, oZemit];
    routers[WMATIC][oZemit] = meshRouter;
  }
}

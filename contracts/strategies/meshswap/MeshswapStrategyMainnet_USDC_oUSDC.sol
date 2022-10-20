//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./MeshswapStrategy.sol";

contract MeshswapStrategyMainnet_USDC_oUSDC is MeshswapStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x111D7a73b40Aa5EE52BF651e8F07Aa26F8e9EFe8);
    address mesh = address(0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address oUsdc = address(0x5bEF2617eCCA9a39924c09017c5F1E25Efbb3bA8);
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
    swapRoutes[WMATIC][oUsdc] = [WMATIC, usdc, oUsdc];
    routers[WMATIC][oUsdc] = meshRouter;
  }
}

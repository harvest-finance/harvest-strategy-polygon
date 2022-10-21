//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./MeshswapStrategy.sol";

contract MeshswapStrategyMainnet_WMATIC_USDT is MeshswapStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x24af68fF6e3501EAf8b52a9F7935225E524FE617);
    address mesh = address(0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a);
    address usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    MeshswapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
    rewardTokens = [mesh];
    swapRoutes[mesh][WMATIC] = [mesh, WMATIC];
    routers[mesh][WMATIC] = meshRouter;
    swapRoutes[WMATIC][usdt] = [WMATIC, usdt];
    routers[WMATIC][usdt] = meshRouter;
  }
}

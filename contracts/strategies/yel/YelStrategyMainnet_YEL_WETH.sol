//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./YelStrategy.sol";

contract YelStrategyMainnet_YEL_WMATIC is YelStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8bAb87ECF28Bf45507Bd745bc70532e968b5c2De);
    address yel = address(0xD3b71117E6C1558c1553305b44988cd944e97300);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    YelStrategy.initializeStrategy(
      _storage,
      underlying,
      _vault,
      address(0x954b15065e4FA1243Cd45a020766511b68Ea9b6E), // master chef contract
      yel,
      1,  // Pool id
      true,
      true
    );
    swapRoutes[wmatic] = [yel, wmatic];
  }
}

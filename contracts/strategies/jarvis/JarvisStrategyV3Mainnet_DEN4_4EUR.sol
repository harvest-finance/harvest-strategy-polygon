//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_DEN4_4EUR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xF84fA79A94aFb742A98EDf2c7a10ef7134b684bC);
    address rewardPool_ = address(0x1e1506b8cF84f8D1C2dbF474BcB6fEC36467C478);
    address rewardToken_ = address(0x53d00635aeC4a6379523341AEBC325857f32FdE1);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 1
    });
  }
}

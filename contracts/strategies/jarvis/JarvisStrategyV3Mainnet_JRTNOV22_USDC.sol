//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTNOV22_USDC is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x68Fd822a2Bda3dB31fFfA68089696ea4e55A9D36);
    address rewardPool_ = address(0xa0044b58b1de085845aeA7BD3256a00EAb4145a2);
    address rewardToken_ = address(0x5eF12a086B8A61C0f11a72b36b5EF451FA17f1f1);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 6
    });
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_DEN3_4EUR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x6E56300267A6Dd07DA0908557E02756747E1c90E);
    address rewardPool_ = address(0x845b7939D7E01fd29d6452CE9DDF9bd3ECf886b2);
    address rewardToken_ = address(0x51e7B5A0e8E942A62562f85D91501fbfA43121fE);

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

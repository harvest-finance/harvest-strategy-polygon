//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTANGLENOV22_2EURagEUR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x4D44f653B885fbddF486a71508Afd63071ca1A6E);
    address rewardPool_ = address(0x7349Cc23B3A3E104ec2FA5A0BB29c8b022508779);
    address rewardToken_ = address(0x63B87304fc9889Ce7356396ea959aA64850a52E7);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 2
    });
  }
}

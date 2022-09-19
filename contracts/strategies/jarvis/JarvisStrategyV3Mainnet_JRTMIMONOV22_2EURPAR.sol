//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTMIMONOV22_2EURPAR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x946bE3eCAebaA3fe2eBb73864ab555A8cfdF49Fd);
    address rewardPool_ = address(0xeA9871A9451c281cc1180100FC074D7F28402288);
    address rewardToken_ = address(0x4Fd52587194a0bfd3AC5b8096D15e1a7230bA2eb);

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

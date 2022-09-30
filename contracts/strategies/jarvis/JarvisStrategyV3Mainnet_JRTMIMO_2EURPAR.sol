//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTMIMO_2EURPAR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x181650dde0A3a457F9e82B00052184AC3FEAAdF3);
    address rewardPool_ = address(0x2BC39d179FAfC32B7796DDA3b936e491C87D245b);
    address rewardToken_ = address(0xAFC780bb79E308990c7387AB8338160bA8071B67);

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

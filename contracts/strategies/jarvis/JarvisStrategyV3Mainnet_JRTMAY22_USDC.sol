//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTMAY22_USDC is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xdaa2C66B06B62bAd2E192be0A93f895c855484ee);
    address rewardPool_ = address(0x0ff93e7CE954A7Ac2ADbBe8F635513cbDB497405);
    address rewardToken_ = address(0xF5f480Edc68589B51F4217E6aA82Ef7Df5cf789e);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 3
    });
  }
}

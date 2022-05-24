//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTJUL22_USDC is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x707C7f22d5E3C0234bCc53aeE51420d6cdD988f9);
    address rewardPool_ = address(0xaB5053e1f6f7fb242f62091BEE8f15c81265EE05);
    address rewardToken_ = address(0xD7f13BeE20D6848D9Ca2F26d9A244AB7bd6CDDc0);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 4
    });
  }
}

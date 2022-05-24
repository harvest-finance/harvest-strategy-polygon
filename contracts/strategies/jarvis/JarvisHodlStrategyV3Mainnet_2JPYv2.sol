//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2JPYv2 is JarvisHodlStrategyV3 {

  address public jpy2v2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xaA91CDD7abb47F821Cf07a2d38Cc8668DEAf1bdc);
    address rewardLp_ = address(0x707C7f22d5E3C0234bCc53aeE51420d6cdD988f9);
    address rewardPool_ = address(0xaB5053e1f6f7fb242f62091BEE8f15c81265EE05);
    address rewardToken_ = address(0xD7f13BeE20D6848D9Ca2F26d9A244AB7bd6CDDc0);
    address hodlVault_ = address(0xcFD80B11fefD581Fc45868ABD0d61e8437C050b1);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 0,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: address(0x0000000000000000000000000000000000000000) // manually set it later
    });
  }
}

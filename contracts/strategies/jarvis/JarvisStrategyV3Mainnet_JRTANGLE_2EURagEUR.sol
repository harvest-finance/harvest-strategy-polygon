//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTANGLE_2EURagEUR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x8c2fe36E51657385d3091E92FbACb79263867F16);
    address rewardPool_ = address(0x9D5d2509C78f7dfEE7FD1b82a49c00Bc9dA70D28);
    address rewardToken_ = address(0x6966D20E33A15baFde7E856147E4E5EaF418E145);

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

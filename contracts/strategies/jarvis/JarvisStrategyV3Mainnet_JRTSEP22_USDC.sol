//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_JRTSEP22_USDC is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x2623D9a6cceb732f9e86125e107A18e7832B27e5);
    address rewardPool_ = address(0x2FAe83B3916e1467C970C113399ee91B31412bCD);
    address rewardToken_ = address(0xcE0248f30d565555B793f42e46E58879F2cDCCa4);

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_SES_2JPY is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x3b76F90A8ab3EA7f0EA717F34ec65d194E5e9737);
    address rewardPool_ = address(0xeb4a4Ba3EF5e3A286Dc49408C27F9BDaA286db84);
    address rewardToken_ = address(0x9120ECada8dc70Dc62cBD49f58e861a09bf83788);

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


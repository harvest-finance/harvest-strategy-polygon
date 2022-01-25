//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_DEN2_4EUR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xEb6f426963140471a7c1E4337877e6dBf834d2A8);
    address rewardPool_ = address(0x9c802D12Da5C7c74104d8cAD9E6084E32c2B70B7);
    address rewardToken_ = address(0xa286eeDAa5aBbAE98F65b152B5057b8bE9893fbB);

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_agDEN_2EUR is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x7d85cCf1B7cbAAB68c580E14fA8C92E32704404f);
    address rewardPool_ = address(0x834579150Cc521e0afAB15568930e3BEc67B865A);
    address rewardToken_ = address(0xEEfF5d27e40A5239f6F28d4b0fbE20acf6432717);

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

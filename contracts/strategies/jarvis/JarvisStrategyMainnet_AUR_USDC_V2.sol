//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategy.sol";

contract JarvisStrategyMainnet_AUR_USDC_V2 is JarvisStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xA623aacf9eB4Fc0a29515F08bdABB0d8Ce385cF7);
    address rewardPool = address(0xc39bD0fAE646Cb026C73943C5B50E703de2a6532);
    address rewardToken = address(0x6Fb2415463e949aF08ce50F83E94b7e008BABf07);
    address rewardLocker = address(0x063DD8b5a42AaE93a014ce5FAbB5B70474667961);
    JarvisStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      rewardToken,
      3,  // Pool id
      underlying,
      rewardLocker
    );
  }
}

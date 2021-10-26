//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategy.sol";

contract JarvisStrategyMainnet_AUR_USDC is JarvisStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xA0fB4487c0935f01cBf9F0274FE3CdB21a965340);
    address rewardPool = address(0x7EB05d3115984547a50Ff0e2d247fB6948E1c252);
    address rewardToken = address(0xfAdE2934b8E7685070149034384fB7863860D86e);
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

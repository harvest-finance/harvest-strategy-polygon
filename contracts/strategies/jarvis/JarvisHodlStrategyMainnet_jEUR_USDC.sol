//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategy.sol";

contract JarvisHodlStrategyMainnet_jEUR_USDC is JarvisHodlStrategy {

  address public jeur_usdc_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xa1219DBE76eEcBf7571Fed6b020Dd9154396B70e);
    address rewardLp = address(0xA0fB4487c0935f01cBf9F0274FE3CdB21a965340);
    address rewardPool = address(0x7EB05d3115984547a50Ff0e2d247fB6948E1c252);
    address rewardToken = address(0xfAdE2934b8E7685070149034384fB7863860D86e);
    address rewardLocker = address(0x063DD8b5a42AaE93a014ce5FAbB5B70474667961);
    JarvisHodlStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      rewardToken,
      0,  // Pool id
      rewardLp,
      rewardLocker,
      address(0x0000000000000000000000000000000000000000), // manually set it later
      address(0x0000000000000000000000000000000000000000) // manually set it later
    );
  }
}

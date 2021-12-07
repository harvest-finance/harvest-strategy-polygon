//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategy.sol";

contract JarvisHodlStrategyMainnet_jEUR_USDC_V2 is JarvisHodlStrategy {

  address public jeur_usdc_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xa1219DBE76eEcBf7571Fed6b020Dd9154396B70e);
    address rewardLp = address(0xA623aacf9eB4Fc0a29515F08bdABB0d8Ce385cF7);
    address rewardPool = address(0xc39bD0fAE646Cb026C73943C5B50E703de2a6532);
    address rewardToken = address(0x6Fb2415463e949aF08ce50F83E94b7e008BABf07);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV2.sol";

contract JarvisHodlStrategyV2Mainnet_4EUR is JarvisHodlStrategyV2 {

  address public eur_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xAd326c253A84e9805559b73A08724e11E49ca651);
    address rewardLp = address(0x4924B6E1207EFb244433294619a5ADD08ACB3dfF);
    address rewardPool = address(0xf8347d0C225e26B45A6ea9a719012F1153D7Ca15);
    address rewardToken = address(0xf379CB529aE58E1A03E62d3e31565f4f7c1F2020);
    JarvisHodlStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      rewardToken,
      1,  // Pool id
      rewardLp,
      address(0x0000000000000000000000000000000000000000), // manually set it later
      address(0x0000000000000000000000000000000000000000) // manually set it later
    );
  }
}

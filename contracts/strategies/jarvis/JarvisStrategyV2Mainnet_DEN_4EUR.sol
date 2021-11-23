//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV2.sol";

contract JarvisStrategyV2Mainnet_DEN_4EUR is JarvisStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4924B6E1207EFb244433294619a5ADD08ACB3dfF);
    address rewardPool = address(0xf8347d0C225e26B45A6ea9a719012F1153D7Ca15);
    address rewardToken = address(0xf379CB529aE58E1A03E62d3e31565f4f7c1F2020);
    JarvisStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      rewardToken,
      0,  // Pool id
      underlying
    );
  }
}

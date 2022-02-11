//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_AUR3_USDC is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xF40E249737c510CCE832286e54cB30E60D4e4656);
    address rewardPool_ = address(0xFAA0f413E67A56cbbE181024279bA5504Ce487EF);
    address rewardToken_ = address(0xBF06D9b11126B140788D842a6ed8dC7885C722B3);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 3
    });
  }
}

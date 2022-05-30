//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_AURJUL22_WETH is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xF9Ce68A9E41f1e7cee5FDCbef99669653Aa61390);
    address rewardPool_ = address(0x8b4D15670CaA3772a29AaC386AB924a0F54Abe48);
    address rewardToken_ = address(0x8C56600D7D8f9239f124c7C52D3fa018fC801A76);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 2
    });
  }
}

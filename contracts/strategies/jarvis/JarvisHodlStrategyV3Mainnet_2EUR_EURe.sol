//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2EUR_EURe is JarvisHodlStrategyV3 {

  address public eur2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x2F3E9CA3bFf85B91D9fe6a9f3e8F9B1A6a4c3cF4);
    address rewardLp_ = address(0x68Fd822a2Bda3dB31fFfA68089696ea4e55A9D36);
    address rewardPool_ = address(0xa0044b58b1de085845aeA7BD3256a00EAb4145a2);
    address rewardToken_ = address(0x5eF12a086B8A61C0f11a72b36b5EF451FA17f1f1);
    address hodlVault_ = address(0xE17e6EfbD0064992D1E4e9a4641f30e40be208a0);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 3,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: address(0x0000000000000000000000000000000000000000) // manually set it later
    });
  }
}

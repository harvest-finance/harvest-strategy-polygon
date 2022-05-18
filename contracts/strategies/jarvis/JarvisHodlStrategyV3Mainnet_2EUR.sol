//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2EUR is JarvisHodlStrategyV3 {

  address public eur2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x2fFbCE9099cBed86984286A54e5932414aF4B717);
    address rewardLp_ = address(0x7d85cCf1B7cbAAB68c580E14fA8C92E32704404f);
    address rewardPool_ = address(0x834579150Cc521e0afAB15568930e3BEc67B865A);
    address rewardToken_ = address(0xEEfF5d27e40A5239f6F28d4b0fbE20acf6432717);
    address hodlVault_ = address(0x48795326FBa34e07076038cC8f03f88a80E71214);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 0,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: address(0x0000000000000000000000000000000000000000) // manually set it later
    });
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_jCHF_WETH is JarvisHodlStrategyV3 {

  address public jchf_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x95697B1b83E0F28017158BF2a2Adc6bA991088EC);
    address rewardLp_ = address(0xF9Ce68A9E41f1e7cee5FDCbef99669653Aa61390);
    address rewardPool_ = address(0x8b4D15670CaA3772a29AaC386AB924a0F54Abe48);
    address rewardToken_ = address(0x8C56600D7D8f9239f124c7C52D3fa018fC801A76);
    address hodlVault_ = address(0x3BB93BdEaF0906819e5D2Eccdc2E9Ce408296dD1);
    address potPool_ = address(0x0000000000000000000000000000000000000000);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 1,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: potPool_
    });
  }
}

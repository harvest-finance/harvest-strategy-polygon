//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2CAD is JarvisHodlStrategyV3 {

  address public cad2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xA69b0D5c0C401BBA2d5162138613B5E38584F63F);
    address rewardLp_ = address(0x32d8513eDDa5AEf930080F15270984A043933A95);
    address rewardPool_ = address(0x16Ef7a2F8156819bAE95CFcE0CA712D01498b665);
    address rewardToken_ = address(0xF65fb31ad1ccb2E7A6Ec3B34BEA4c81b68af6695);
    address hodlVault_ = address(0x7f7136760ce6235b0889704B01bE23E6E8220e7B);

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

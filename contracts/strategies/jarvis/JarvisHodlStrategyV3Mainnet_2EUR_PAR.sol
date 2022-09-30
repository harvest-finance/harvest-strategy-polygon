//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2EUR_PAR is JarvisHodlStrategyV3 {

  address public eur2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x0f110c55EfE62c16D553A3d3464B77e1853d0e97);
    address rewardLp_ = address(0x181650dde0A3a457F9e82B00052184AC3FEAAdF3);
    address rewardPool_ = address(0x2BC39d179FAfC32B7796DDA3b936e491C87D245b);
    address rewardToken_ = address(0xAFC780bb79E308990c7387AB8338160bA8071B67);
    address hodlVault_ = address(0x173ce98897F7c846d7282555B52362B4233d2196);

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

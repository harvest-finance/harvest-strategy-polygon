//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2EUR_EURT is JarvisHodlStrategyV3 {

  address public eur2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x2C3cc8e698890271c8141be9F6fD6243d56B39f1);
    address rewardLp_ = address(0x2623D9a6cceb732f9e86125e107A18e7832B27e5);
    address rewardPool_ = address(0x2FAe83B3916e1467C970C113399ee91B31412bCD);
    address rewardToken_ = address(0xcE0248f30d565555B793f42e46E58879F2cDCCa4);
    address hodlVault_ = address(0x587155256938F081D6e48829d45849BD856Fd969);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 4,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: address(0x0000000000000000000000000000000000000000) // manually set it later
    });
  }
}

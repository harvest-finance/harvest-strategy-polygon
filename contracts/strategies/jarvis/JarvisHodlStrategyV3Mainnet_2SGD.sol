//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2SGD is JarvisHodlStrategyV3 {

  address public sgd2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xeF75E9C7097842AcC5D0869E1dB4e5fDdf4BFDDA);
    address rewardLp_ = address(0xdaa2C66B06B62bAd2E192be0A93f895c855484ee);
    address rewardPool_ = address(0x0ff93e7CE954A7Ac2ADbBe8F635513cbDB497405);
    address rewardToken_ = address(0xF5f480Edc68589B51F4217E6aA82Ef7Df5cf789e);
    address hodlVault_ = address(0x95b730ED766F4e385016144fA30E96b78EBd09f5);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 2,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: address(0x0000000000000000000000000000000000000000) // manually set it later
    });
  }
}

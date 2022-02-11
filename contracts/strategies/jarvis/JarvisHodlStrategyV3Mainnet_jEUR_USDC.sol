//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_jEUR_USDC is JarvisHodlStrategyV3 {

  address public jeur_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xa1219DBE76eEcBf7571Fed6b020Dd9154396B70e);
    address rewardLp_ = address(0xF40E249737c510CCE832286e54cB30E60D4e4656);
    address rewardPool_ = address(0xFAA0f413E67A56cbbE181024279bA5504Ce487EF);
    address rewardToken_ = address(0xBF06D9b11126B140788D842a6ed8dC7885C722B3);
    address hodlVault_ = address(0x102Df50dB22407B64a8A6b11734c8743B6AeF953);
    address potPool_ = address(0xf25474FBf9812bE2ef76abf4297A27411C156403);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 0,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: potPool_
    });
  }
}

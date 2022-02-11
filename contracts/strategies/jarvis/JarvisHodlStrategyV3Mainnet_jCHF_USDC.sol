//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_jCHF_USDC is JarvisHodlStrategyV3 {

  address public jchf_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x439E6A13a5ce7FdCA2CC03bF31Fb631b3f5EF157);
    address rewardLp_ = address(0xF40E249737c510CCE832286e54cB30E60D4e4656);
    address rewardPool_ = address(0xFAA0f413E67A56cbbE181024279bA5504Ce487EF);
    address rewardToken_ = address(0xBF06D9b11126B140788D842a6ed8dC7885C722B3);
    address hodlVault_ = address(0x102Df50dB22407B64a8A6b11734c8743B6AeF953);
    address potPool_ = address(0x24Aa3547962872351c30F1127430172317C05FEC);

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

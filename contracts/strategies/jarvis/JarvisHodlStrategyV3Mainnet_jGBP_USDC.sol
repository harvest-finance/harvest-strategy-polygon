//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_jGBP_USDC is JarvisHodlStrategyV3 {

  address public jgbp_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xbb2d00675B775E0F8acd590e08DA081B2a36D3a6);
    address rewardLp_ = address(0xF40E249737c510CCE832286e54cB30E60D4e4656);
    address rewardPool_ = address(0xFAA0f413E67A56cbbE181024279bA5504Ce487EF);
    address rewardToken_ = address(0xBF06D9b11126B140788D842a6ed8dC7885C722B3);
    address hodlVault_ = address(0x102Df50dB22407B64a8A6b11734c8743B6AeF953);
    address potPool_ = address(0x877635e68C1E943D6d6B777C0e847Cd7aE5A01BE);

    JarvisHodlStrategyV3.initializeBaseStrategy({
    __storage: __storage,
    _underlying: underlying_,
    _vault: _vault,
    _rewardPool: rewardPool_,
    _rewardToken: rewardToken_,
    _poolId: 2,
    _rewardLp: rewardLp_,
    _hodlVault: hodlVault_,
    _potPool: potPool_
    });
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisHodlStrategyV3.sol";

contract JarvisHodlStrategyV3Mainnet_2JPY is JarvisHodlStrategyV3 {

  address public jpy2_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A);
    address rewardLp_ = address(0x3b76F90A8ab3EA7f0EA717F34ec65d194E5e9737);
    address rewardPool_ = address(0xeb4a4Ba3EF5e3A286Dc49408C27F9BDaA286db84);
    address rewardToken_ = address(0x9120ECada8dc70Dc62cBD49f58e861a09bf83788);
    address hodlVault_ = address(0x483d1e18E67bF69ef555c798807DaDbE7757311D);

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

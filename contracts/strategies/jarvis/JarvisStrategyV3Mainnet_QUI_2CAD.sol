//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JarvisStrategyV3.sol";

contract JarvisStrategyV3Mainnet_QUI_2CAD is JarvisStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address __storage,
    address _vault
  ) public initializer {
    address underlying_ = address(0x32d8513eDDa5AEf930080F15270984A043933A95);
    address rewardPool_ = address(0x16Ef7a2F8156819bAE95CFcE0CA712D01498b665);
    address rewardToken_ = address(0xF65fb31ad1ccb2E7A6Ec3B34BEA4c81b68af6695);

    JarvisStrategyV3.initializeBaseStrategy({
      __storage: __storage,
      _underlying: underlying_,
      _vault: _vault,
      _rewardPool: rewardPool_,
      _rewardToken: rewardToken_,
      _poolId: 1
    });
  }
}

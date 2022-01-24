//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/DualRewardsLPStrategy.sol";

contract QuickDualRewardStrategyMainnet_PSP_MATIC is DualRewardsLPStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x7AfC060acCA7ec6985d982dD85cC62B111CAc7a7);
    address psp = address(0x42d61D766B85431666B39B89C43011f24451bFf6);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address rewardPool = address(0x64D2B3994F64E3E82E48CC92e1122489e88e8727);
    DualRewardsLPStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool, //rewardPool
      wmatic,  // baseReward (for profit notification)
      true //isQuickPair
    );
    rewardTokens = [quick, psp];
    BASE2deposit[psp] = [wmatic, psp];
    reward2BASE[quick] = [quick, wmatic];
    reward2BASE[psp] = [psp, wmatic];
    useQuick[psp] = true;
    useQuick[quick] = true;
  }
}

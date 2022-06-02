//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/DualRewardsLPStrategy.sol";

contract QuickDualRewardStrategyMainnet_MATIC_USDC is DualRewardsLPStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address rewardPool = address(0x14977e7E263FF79c4c3159F497D9551fbE769625);
    DualRewardsLPStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool, //rewardPool
      wmatic,  // baseReward (for profit notification)
      true //isQuickPair
    );
    rewardTokens = [quick];
    BASE2deposit[usdc] = [wmatic, usdc];
    reward2BASE[quick] = [quick, wmatic];
    useQuick[usdc] = true;
    useQuick[quick] = true;
  }
}

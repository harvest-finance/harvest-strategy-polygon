//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MStableStrategy.sol";

contract MStableStrategyMainnet_mUSD is MStableStrategy {

    address public mstable_musd_unused; // just a differentiator for the bytecode

    constructor() public {}

    function initializeStrategy(
      address _storage,
      address _vault
    ) public initializer {
        address savingsContract = address(0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af); // imUSD savings contract
        address underlying = address(0xE840B73E5287865EEc17d250bFb1536704B43B21); // mUSD
        address rewardPool = address(0x32aBa856Dc5fFd5A56Bcd182b13380e5C855aa29); // imUSD staking contract (v-imUSD Vault)
        address mta = address(0xF501dd45a1198C2E1b5aEF5314A68B9006D842E0); // reward token 1 of strategy is MTA (rewardToken)
        address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // reward token 2 of strategy is WMATIC (platformToken)

        address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619); // reward token for harvest fees after liquidation

        bytes32 balancerMtaPoolId = bytes32(0x614b5038611729ed49e0ded154d8a5d3af9d1d9e00010000000000000000001d);

        MStableStrategy._initializeBaseStrategy(
          _storage,
          underlying,
          _vault,
          rewardPool, // reward pool
          weth, // reward token
          savingsContract
        );

        rewardTokens = [mta, wmatic];
        // reward tokens of strategy (MTA, WMATIC) -> fee reward token (WETH)
        storedLiquidationDexes[wmatic][weth] = quickDex;
        storedLiquidationDexes[mta][weth] = balancerDex;
        storedBalancerPoolIds[mta][weth] = balancerMtaPoolId;
        // fee reward token (WETH) -> underlying (mUSD)
        // Note: have to go through DAI to swap on mStable
        storedLiquidationDexes[weth][dai] = quickDex;
        storedLiquidationDexes[dai][underlying] = mstableDex;
    }
}

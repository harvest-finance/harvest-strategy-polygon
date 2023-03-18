//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_stETH is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x65Fe9314bE50890Fb01457be076fAFD05Ff32B9A);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address ldo = address(0xC3C7d422809852031b44ab29EEC9F1EfF2A58756);
    address gauge = address(0x94e5C0270250d9E13B0545279807eF8c6c4Ed2a3);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x65fe9314be50890fb01457be076fafd05ff32b9a000000000000000000000a96,  // Pool id
      weth,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, ldo];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[ldo] = [ldo, wmatic, weth];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

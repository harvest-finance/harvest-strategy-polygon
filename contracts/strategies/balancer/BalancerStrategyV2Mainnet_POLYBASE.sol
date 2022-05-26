//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_POLYBASE is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0297e37f1873D2DAb4487Aa67cD56B58E2F27875);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x068Ff98072d3eB848D012e3390703BB507729ed6);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002,  // Pool id
      weth,   //depositToken
      2,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [wmatic, usdc, weth, bal];
    rewardTokens = [bal];
  }
}

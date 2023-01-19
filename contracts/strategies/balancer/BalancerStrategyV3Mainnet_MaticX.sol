//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_MaticX is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xb20fC01D21A50d2C734C4a1262B4404d41fA7BF0);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address sd = address(0x1d734A02eF1e1f5886e66b0673b71Af5B53ffA94);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address gauge = address(0xdFFe97094394680362Ec9706a759eB9366d804C2);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xb20fc01d21a50d2c734c4a1262b4404d41fa7bf000000000000000000000075c,  // Pool id
      wmatic,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, sd];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[sd] = [sd, usdc, weth];
    WETH2deposit = [weth, wmatic];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
  }
}

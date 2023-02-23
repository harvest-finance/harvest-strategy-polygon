//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_bbamusd is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x48e6B98ef6329f8f0A30eBB8c7C960330d648085);
    address bbamdai = address(0x178E029173417b1F9C8bC16DCeC6f697bC323746);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address gauge = address(0x1c514fEc643AdD86aeF0ef14F4add28cC3425306);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x48e6b98ef6329f8f0a30ebb8c7c960330d64808500000000000000000000075b,  // Pool id
      bbamdai,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, dai, bbamdai];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[dai][bbamdai] = 0x178e029173417b1f9c8bc16dcec6f697bc323746000000000000000000000758;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_MaticX is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xC17636e36398602dd37Bb5d1B3a9008c7629005f);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address maticx = address(0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x48534d027f8962692122dB440714fFE88Ab1fA85);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xc17636e36398602dd37bb5d1b3a9008c7629005f0002000000000000000004c4,  // Pool id
      wmatic,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [wmatic, maticx];
    rewardTokens = [bal];
    WETH2deposit = [weth, wmatic];
    useQuick[wmatic] = true;
  }
}

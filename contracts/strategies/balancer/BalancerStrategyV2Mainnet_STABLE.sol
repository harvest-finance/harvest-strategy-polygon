//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_STABLE is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x06Df3b2bbB68adc8B0e302443692037ED9f91b42);
    address usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address mimatic = address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address gauge = address(0x72843281394E68dE5d55BCF7072BB9B2eBc24150);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000012,  // Pool id
      usdc,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [usdc, dai, mimatic, usdt];
    WETH2deposit = [weth, usdc];
    rewardTokens = [bal];
    useQuick[usdc] = true;
  }
}

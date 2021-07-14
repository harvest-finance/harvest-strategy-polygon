//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy5Token.sol";

contract BalancerStrategyMainnet_QIPOOL is BalancerStrategy5Token {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xf461f2240B66D55Dcf9059e26C022160C06863BF);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address qi = address(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address mimatic = address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    BalancerStrategy5Token.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xf461f2240b66d55dcf9059e26c022160c06863bf000100000000000000000006,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      usdc,   //depositToken
      1,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002 //bal2weth pid
    );
    poolAssets = [wmatic, usdc, qi, bal, mimatic];
    WETH2deposit = [weth, usdc];
    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[qi] = [qi, mimatic, usdc, weth];
    rewardTokens = [bal, wmatic, qi];
    useQuick[wmatic] = true;
    useQuick[qi] = true;
  }
}

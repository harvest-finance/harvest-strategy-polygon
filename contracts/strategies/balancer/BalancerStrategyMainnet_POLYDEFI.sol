//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy5Token.sol";

contract BalancerStrategyMainnet_POLYDEFI is BalancerStrategy5Token {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x36128D5436d2d70cab39C9AF9CcE146C38554ff0);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address link = address(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address aave = address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);
    BalancerStrategy5Token.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x36128d5436d2d70cab39c9af9cce146c38554ff0000100000000000000000008,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      2,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002 //bal2weth pid
    );
    poolAssets = [usdc, link, weth, bal, aave];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_POLYDEFI2 is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xce66904B68f1f070332Cbc631DE7ee98B650b499);
    address link = address(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address aave = address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xce66904b68f1f070332cbc631de7ee98b650b499000100000000000000000009,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      weth,   //depositToken
      1,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      4 //nTokens
    );
    poolAssets = [link, weth, bal, aave];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
  }
}

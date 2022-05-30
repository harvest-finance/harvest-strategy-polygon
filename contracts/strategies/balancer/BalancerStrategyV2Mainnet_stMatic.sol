//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV2.sol";

contract BalancerStrategyV2Mainnet_stMatic is BalancerStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address stmatic = address(0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0x9928340f9E1aaAd7dF1D95E27bd9A5c715202a56);
    BalancerStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366,  // Pool id
      wmatic,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [wmatic, stmatic];
    rewardTokens = [bal];
    WETH2deposit = [weth, wmatic];
    useQuick[wmatic] = true;
  }
}

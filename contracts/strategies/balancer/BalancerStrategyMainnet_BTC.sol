//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_BTC is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFeadd389a5c427952D8fdb8057D6C8ba1156cC56);
    address wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address renBTC = address(0xDBf31dF14B66535aF65AaC99C32e9eA844e14501);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xfeadd389a5c427952d8fdb8057d6c8ba1156cc5600020000000000000000001e,  // Pool id
      500,    //Liquidation ratio, liquidate 50% on doHardWork
      wbtc,   //depositToken
      0,      //depositArrayIndex
      0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002, //bal2weth pid
      2 //nTokens
    );
    poolAssets = [wbtc, renBTC];
    WETH2deposit = [weth, wbtc];
    reward2WETH[wmatic] = [wmatic, weth];
    rewardTokens = [bal, wmatic];
    useQuick[wmatic] = true;
    useQuick[wbtc] = false;
  }
}

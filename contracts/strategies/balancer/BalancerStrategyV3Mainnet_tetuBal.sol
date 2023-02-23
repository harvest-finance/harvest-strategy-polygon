//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategyV3.sol";

contract BalancerStrategyV3Mainnet_tetuBal is BalancerStrategyV3 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xB797AdfB7b268faeaA90CAdBfEd464C76ee599Cd);
    address wethBal = address(0x3d468AB2329F296e1b9d8476Bb54Dd77D8c2320f);
    address bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
    address gauge = address(0xAA59736b80cf77d1E7D56B7bbA5A8050805F5064);
    BalancerStrategyV3.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xb797adfb7b268faeaa90cadbfed464c76ee599cd0002000000000000000005ba,  // Pool id
      wethBal,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, wethBal];
    poolIds[bal][weth] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    poolIds[weth][wethBal] = 0x3d468ab2329f296e1b9d8476bb54dd77d8c2320f000200000000000000000426;
    deposit[weth][wethBal] = true;
  }
}

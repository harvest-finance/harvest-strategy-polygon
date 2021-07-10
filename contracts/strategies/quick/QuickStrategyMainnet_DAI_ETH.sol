//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_DAI_ETH is SNXRewardUniLPStrategy {

  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public dai_eth = address(0x4A35582a710E1F4b2030A3F826DA20BfB6703C09);
  address public dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0x785AaCd49c1Aa3ca573F2a32Bb90030A205b8147);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, dai_eth, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == dai_eth, "Underlying mismatch");
    uniswapRoutes[dai] = [quick, eth, dai];
    uniswapRoutes[eth] = [quick, eth];
  }
}

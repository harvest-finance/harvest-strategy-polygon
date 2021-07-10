//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_USDT_ETH is SNXRewardUniLPStrategy {

  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public usdt_eth = address(0xF6422B997c7F54D1c6a6e103bcb1499EeA0a7046);
  address public usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0xB26bfcD52D997211C13aE4C35E82ced65AF32A02);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, usdt_eth, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == usdt_eth, "Underlying mismatch");
    uniswapRoutes[usdt] = [quick, eth, usdt];
    uniswapRoutes[eth] = [quick, eth];
  }
}

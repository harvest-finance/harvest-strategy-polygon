//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_ETH_MATIC is SNXRewardUniLPStrategy {

  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public eth_wmatic = address(0xadbF1854e5883eB8aa7BAf50705338739e558E5b);
  address public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0x8FF56b5325446aAe6EfBf006a4C1D88e4935a914);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, eth_wmatic, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == eth_wmatic, "Underlying mismatch");
    uniswapRoutes[wmatic] = [quick, wmatic];
    uniswapRoutes[eth] = [quick, eth];
  }
}

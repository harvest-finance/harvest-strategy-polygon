//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_MATIC_QUICK is SNXRewardUniLPStrategy {

  address public wmatic_quick = address(0x019ba0325f1988213D448b3472fA1cf8D07618d7);
  address public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0x7Ca29F0DB5Db8b88B332Aa1d67a2e89DfeC85E7E);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, wmatic_quick, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == wmatic_quick, "Underlying mismatch");
    uniswapRoutes[wmatic] = [quick, wmatic];
  }
}

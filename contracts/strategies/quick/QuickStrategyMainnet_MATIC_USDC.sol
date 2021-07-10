//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_MATIC_USDC is SNXRewardUniLPStrategy {

  address public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address public wmatic_usdc = address(0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827);
  address public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0x6C6920aD61867B86580Ff4AfB517bEc7a499A7Bb);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, wmatic_usdc, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == wmatic_usdc, "Underlying mismatch");
    uniswapRoutes[wmatic] = [quick, wmatic];
    uniswapRoutes[usdc] = [quick, usdc];
  }
}

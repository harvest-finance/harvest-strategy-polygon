//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_WBTC_USDC is SNXRewardUniLPStrategy {

  address public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address public wbtc_usdc = address(0xF6a637525402643B0654a54bEAd2Cb9A83C8B498);
  address public wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public SNXRewardPool = address(0x8f2ac4EC8982bF1699a6EeD696e204FA2ccD5D91);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, wbtc_usdc, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == wbtc_usdc, "Underlying mismatch");
    uniswapRoutes[wbtc] = [quick, eth, wbtc];
    uniswapRoutes[usdc] = [quick, usdc];
  }
}

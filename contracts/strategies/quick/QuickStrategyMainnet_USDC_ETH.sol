//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_USDC_ETH is SNXRewardUniLPStrategy {

  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public usdc_eth = address(0x853Ee4b2A13f8a742d64C8F088bE7bA2131f670d);
  address public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0x4A73218eF2e820987c59F838906A82455F42D98b);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, usdc_eth, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == usdc_eth, "Underlying mismatch");
    uniswapRoutes[usdc] = [quick, usdc];
    uniswapRoutes[eth] = [quick, eth];
  }
}

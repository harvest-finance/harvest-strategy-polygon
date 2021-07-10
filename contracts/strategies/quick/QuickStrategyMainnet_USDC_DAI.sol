//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_USDC_DAI is SNXRewardUniLPStrategy {

  address public dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
  address public usdc_dai = address(0xf04adBF75cDFc5eD26eeA4bbbb991DB002036Bdd);
  address public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public SNXRewardPool = address(0xEd8413eCEC87c3d4664975743c02DB3b574012a7);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, usdc_dai, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == usdc_dai, "Underlying mismatch");
    uniswapRoutes[usdc] = [quick, usdc];
    uniswapRoutes[dai] = [quick, eth, dai];
  }
}

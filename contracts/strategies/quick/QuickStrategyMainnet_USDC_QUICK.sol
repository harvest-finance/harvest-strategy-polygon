//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_USDC_QUICK is SNXRewardUniLPStrategy {

  address public usdc_quick = address(0x1F1E4c845183EF6d50E9609F16f6f9cAE43BC9Cb);
  address public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0x8cFad56Eb742BA8CAEA813e47779E9C38f27cA6E);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, usdc_quick, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == usdc_quick, "Underlying mismatch");
    uniswapRoutes[usdc] = [quick, usdc];
  }
}

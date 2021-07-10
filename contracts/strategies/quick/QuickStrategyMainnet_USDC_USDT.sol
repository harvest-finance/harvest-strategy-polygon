//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_USDC_USDT is SNXRewardUniLPStrategy {

  address public usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
  address public usdc_usdt = address(0x2cF7252e74036d1Da831d11089D326296e64a728);
  address public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public SNXRewardPool = address(0x251d9837a13F38F3Fe629ce2304fa00710176222);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, usdc_usdt, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == usdc_usdt, "Underlying mismatch");
    uniswapRoutes[usdc] = [quick, usdc];
    uniswapRoutes[usdt] = [quick, eth, usdt];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_QUICK_ETH is SNXRewardUniLPStrategy {

  address public quick_eth = address(0x1Bd06B96dd42AdA85fDd0795f3B4A79DB914ADD5);
  address public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0xD1C762861AAe85dF2e586a668A793AAfF820932b);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, quick_eth, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == quick_eth, "Underlying mismatch");
    uniswapRoutes[eth] = [quick, eth];
  }
}

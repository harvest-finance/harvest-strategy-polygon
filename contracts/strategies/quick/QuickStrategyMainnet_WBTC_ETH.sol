//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_WBTC_ETH is SNXRewardUniLPStrategy {

  address public weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public wbtc_weth = address(0xdC9232E2Df177d7a12FdFf6EcBAb114E2231198D);
  address public wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0x2972175e1a35C403B5596354D6459C34Ae6A1070);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(
    _storage,
    wbtc_weth, 
    _vault,
    SNXRewardPool,
    quick,
    routerAddress,
    true // isDragonLairPool (Converts dQuick to QUICK for liquidation)
  )
  public {
    require(IVault(_vault).underlying() == wbtc_weth, "Underlying mismatch");
    uniswapRoutes[wbtc] = [quick, weth, wbtc];
    uniswapRoutes[weth] = [quick, weth];
  }
}

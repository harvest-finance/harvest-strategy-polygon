//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/ape-base/MiniApeV2Strategy.sol";

contract ApeStrategyMainnet_ETH_MATIC is MiniApeV2Strategy {

  address constant public weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address constant public banana = address(0x5d47bAbA0d66083C52009271faF3F50DCc01023C);
  address constant public weth_matic = address(0x6Cf8654e85AB489cA7e70189046D507ebA233613);
  address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address constant public miniApe = address(0x54aff400858Dcac39797a81894D9920f16972D1D);
  
  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {

    MiniApeV2Strategy.initializeBaseStrategy(
      _storage, 
      weth_matic, 
      _vault, 
      miniApe, 
      banana, 
      1
    );

    require(IVault(_vault).underlying() == weth_matic, "Underlying mismatch");
    
    uniswapRoutes[wmatic] = [banana, wmatic];
    uniswapRoutes[weth] = [banana, wmatic, weth];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/ape-base/MiniApeV2Strategy.sol";

contract ApeStrategyMainnet_USDT_MATIC is MiniApeV2Strategy {

  address constant public usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
  address constant public banana = address(0x5d47bAbA0d66083C52009271faF3F50DCc01023C);
  address constant public usdt_matic = address(0x65D43B64E3B31965Cd5EA367D4c2b94c03084797);
  address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address constant public miniApe = address(0x54aff400858Dcac39797a81894D9920f16972D1D);
  
  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {

    MiniApeV2Strategy.initializeBaseStrategy(
      _storage, 
      usdt_matic, 
      _vault, 
      miniApe, 
      banana, 
      3
    );

    require(IVault(_vault).underlying() == usdt_matic, "Underlying mismatch");
    
    uniswapRoutes[usdt] = [banana, wmatic, usdt];
    uniswapRoutes[wmatic] = [banana, wmatic];
  }
}

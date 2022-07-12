//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/ape-base/MiniApeV2Strategy.sol";

contract ApeStrategyMainnet_BTC_MATIC is MiniApeV2Strategy {

  address constant public wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
  address constant public banana = address(0x5d47bAbA0d66083C52009271faF3F50DCc01023C);
  address constant public btc_matic = address(0xe82635a105c520fd58e597181cBf754961d51E3e);
  address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address constant public miniApe = address(0x54aff400858Dcac39797a81894D9920f16972D1D);
  
  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {

    MiniApeV2Strategy.initializeBaseStrategy(
      _storage, 
      btc_matic, 
      _vault, 
      miniApe, 
      banana, 
      4
    );

    require(IVault(_vault).underlying() == btc_matic, "Underlying mismatch");
    
    uniswapRoutes[wmatic] = [banana, wmatic];
    uniswapRoutes[wbtc] = [banana, wmatic, wbtc];
  }
}

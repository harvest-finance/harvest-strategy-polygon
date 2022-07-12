//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/ape-base/MiniApeV2Strategy.sol";

contract ApeStrategyMainnet_BNB_MATIC is MiniApeV2Strategy {

  address constant public bnb = address(0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F);
  address constant public banana = address(0x5d47bAbA0d66083C52009271faF3F50DCc01023C);
  address constant public bnb_matic = address(0x0359001070cF696D5993E0697335157a6f7dB289);
  address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address constant public miniApe = address(0x54aff400858Dcac39797a81894D9920f16972D1D);
  
  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {

    MiniApeV2Strategy.initializeBaseStrategy(
      _storage, 
      bnb_matic, 
      _vault, 
      miniApe, 
      banana, 
      6
    );

    require(IVault(_vault).underlying() == bnb_matic, "Underlying mismatch");
    
    uniswapRoutes[bnb] = [banana, wmatic, bnb];
    uniswapRoutes[wmatic] = [banana, wmatic];
  }
}

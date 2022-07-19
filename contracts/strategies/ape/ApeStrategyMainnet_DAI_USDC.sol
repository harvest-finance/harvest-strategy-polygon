//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/ape-base/MiniApeV2Strategy.sol";

contract ApeStrategyMainnet_DAI_USDC is MiniApeV2Strategy {

  address constant public dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
  address constant public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address constant public banana = address(0x5d47bAbA0d66083C52009271faF3F50DCc01023C);
  address constant public dai_usdc = address(0x5b13B583D4317aB15186Ed660A1E4C65C10da659);
  address constant public wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address constant public miniApe = address(0x54aff400858Dcac39797a81894D9920f16972D1D);
  
  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {

    MiniApeV2Strategy.initializeBaseStrategy(
      _storage, 
      dai_usdc, 
      _vault, 
      miniApe, 
      banana, 
      5
    );

    require(IVault(_vault).underlying() == dai_usdc, "Underlying mismatch");
    
    uniswapRoutes[dai] = [banana, wmatic, dai];
    uniswapRoutes[usdc] = [banana, wmatic, dai, usdc];
  }
}

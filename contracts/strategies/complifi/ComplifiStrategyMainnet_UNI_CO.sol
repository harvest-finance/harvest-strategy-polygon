//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./ComplifiStrategy.sol";

contract ComplifiStrategyMainnet_UNI_CO is ComplifiStrategy {

  address public uniCO_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0d2c9286c01B50B3A66417aD00Ac82Ae0aE9C5ab);
    address proxy = address(0x5810433Ea1E225c11F0C7d66082026d8A83FC765);
    address comfi = address(0x72bba3Aa59a1cCB1591D7CDDB714d8e4D5597E96);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address uni = address(0xb33EaAd8d922B1083446DC23f610c2567fB5180f);
    ComplifiStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0x0517A1A0469ed604EaAAbA110fb7234b14f73827), // master chef contract
      comfi,
      uni,
      proxy
    );
    // comfi is token0, weth is token1
    liquidationPath = [comfi, usdc, weth, uni];
  }
}

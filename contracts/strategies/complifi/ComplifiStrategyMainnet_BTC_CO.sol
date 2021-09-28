//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./ComplifiStrategy.sol";

contract ComplifiStrategyMainnet_BTC_CO is ComplifiStrategy {

  address public btcCO_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE82c4E2ce680B98fC732283d9b42F1994e2f5c7b);
    address proxy = address(0x5810433Ea1E225c11F0C7d66082026d8A83FC765);
    address comfi = address(0x72bba3Aa59a1cCB1591D7CDDB714d8e4D5597E96);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    ComplifiStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0x0517A1A0469ed604EaAAbA110fb7234b14f73827), // master chef contract
      comfi,
      wbtc,
      proxy
    );
    // comfi is token0, weth is token1
    liquidationPath = [comfi, usdc, weth, wbtc];
  }
}

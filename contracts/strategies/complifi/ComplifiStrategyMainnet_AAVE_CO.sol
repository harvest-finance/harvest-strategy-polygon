//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./ComplifiStrategy.sol";

contract ComplifiStrategyMainnet_AAVE_CO is ComplifiStrategy {

  address public aaveCO_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xA5629F1B865f00Ac3361b34920eB7BA5db464ac5);
    address proxy = address(0x5810433Ea1E225c11F0C7d66082026d8A83FC765);
    address comfi = address(0x72bba3Aa59a1cCB1591D7CDDB714d8e4D5597E96);
    address aave = address(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    ComplifiStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0x0517A1A0469ed604EaAAbA110fb7234b14f73827), // master chef contract
      comfi,
      aave,
      proxy
    );
    // comfi is token0, weth is token1
    liquidationPath = [comfi, usdc, weth, aave];
  }
}

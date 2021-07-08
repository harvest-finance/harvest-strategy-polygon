//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./ComplifiStrategy.sol";

//TO BE UPDATED WITH ADDRESSES WHEN THEY ARE KNOWN

contract ComplifiStrategyMainnet_COMFI_WETH is ComplifiStrategy {

  address public comfi_weth_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0);
    address comfi = address(0x72bba3Aa59a1cCB1591D7CDDB714d8e4D5597E96);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    ComplifiStrategy.initializeStrategy(
      _storage,
      underlying,
      _vault,
      address(0), // master chef contract
      comfi,
      0,  // Pool id
      true, // is LP asset
      true // true = use Quickswap for liquidating
    );
    // comfi is token0, weth is token1
    swapRoutes[weth] = [comfi, weth];
  }
}

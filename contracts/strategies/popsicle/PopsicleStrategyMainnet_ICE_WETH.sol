//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./PopsicleStrategy.sol";

contract PopsicleStrategtMainnet_ICE_WETH is PopsicleStrategy {

  address public ice_eth_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x941eb28e750C441AEF465a89E43DDfec2561830b);
    address ice = address(0x4e1581f01046eFDd7a1a2CDB0F82cdd7F71F2E59);
    address weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    PopsicleStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0xbf513aCe2AbDc69D38eE847EFFDaa1901808c31c), // master chef contract
      ice,
      0,  // Pool id
      true // is LP asset
    );
    swapRoutes[weth] = [ice, weth];
  }
}

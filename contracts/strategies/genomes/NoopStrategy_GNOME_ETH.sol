//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/noop/NoopStrategyUpgradeable.sol";

contract NoopStrategy_GNOME_ETH is NoopStrategyUpgradeable {

  address public gnome_eth_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xc1214b61965594b3e08Ea4950747d5A077Cd1886);
    NoopStrategyUpgradeable.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
  }
}

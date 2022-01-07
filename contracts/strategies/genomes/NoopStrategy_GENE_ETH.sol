//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/noop/NoopStrategyUpgradeable.sol";

contract NoopStrategy_GENE_ETH is NoopStrategyUpgradeable {

  address public gene_eth_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x3d4219987fBb25C3DcF73FbD9AA85FbE3C7411D9);
    NoopStrategyUpgradeable.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
  }
}

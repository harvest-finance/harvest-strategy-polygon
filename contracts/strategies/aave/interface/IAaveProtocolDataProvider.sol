// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IAaveProtocolDataProvider {

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

}

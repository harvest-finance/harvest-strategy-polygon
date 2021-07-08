//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CurveStrategyAave.sol";

contract CurveStrategyAaveMainnet is CurveStrategyAave {

  address public aave_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171);
    address gauge = address(0xe381C25de995d62b453aF8B931aAc84fcCaa7A62);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address aaveCurveDeposit = address(0x445FE580eF8d70FF569aB36e80c647af338db351);
    CurveStrategyAave.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge, //rewardPool
      wmatic, //rewardToken
      true, //useQuick
      1, //depositArrayPosition
      aaveCurveDeposit,
      usdc //depositToken
    );
    reward2deposit = [wmatic, usdc];
  }
}

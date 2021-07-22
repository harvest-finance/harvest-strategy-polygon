//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CurveStrategy.sol";

contract CurveStrategyAaveMainnet is CurveStrategy {

  address public aave_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171);
    address gauge = address(0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address crv = address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address aaveCurveDeposit = address(0x445FE580eF8d70FF569aB36e80c647af338db351);
    CurveStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge, //rewardPool
      1, //depositArrayPosition
      aaveCurveDeposit,
      usdc, //depositToken
      3,
      true
    );
    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[crv] = [crv, weth];
    WETH2deposit = [weth, usdc];
    rewardTokens = [crv, wmatic];
    useQuick[crv] = false;
    useQuick[wmatic] = true;
    useQuick[usdc] = true;
  }
}

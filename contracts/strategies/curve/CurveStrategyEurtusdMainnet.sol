//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CurveStrategy.sol";

contract CurveStrategyEurtusdMainnet is CurveStrategy {

  address public eurtusd_unused; // just a differentiator for the bytecode

  constructor() public {}


  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x600743B1d8A96438bD46836fD34977a00293f6Aa);
    address gauge = address(0x40c0e9376468b4f257d15F8c47E5D0C646C28880);
    address crv = address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    address dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address deposit = address(0x225FB4176f0E20CDb66b4a3DF70CA3063281E855);
    CurveStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge, //rewardPool
      1, //depositArrayPosition
      deposit,
      dai, //depositToken
      4,
      false
    );
    reward2WETH[crv] = [crv, weth];
    WETH2deposit = [weth, dai];
    rewardTokens = [crv];
    useQuick[crv] = false;
  }
}
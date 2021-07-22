//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CurveStrategy.sol";

contract CurveStrategyRenMainnet is CurveStrategy {

  address public ren_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xf8a57c1d3b9629b77b6726a042ca48990A84Fb49);
    address gauge = address(0xffbACcE0CC7C19d46132f1258FC16CF6871D153c);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address crv = address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    address wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address renCurveDeposit = address(0xC2d95EEF97Ec6C17551d45e77B590dc1F9117C67);
    CurveStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge, //rewardPool
      0, //depositArrayPosition
      renCurveDeposit,
      wbtc, //depositToken
      2,
      true
    );
    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[crv] = [crv, weth];
    WETH2deposit = [weth, wbtc];
    rewardTokens = [crv, wmatic];
    useQuick[crv] = false;
    useQuick[wmatic] = true;
    useQuick[wbtc] = false;
  }
}

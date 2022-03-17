//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CurveStrategy.sol";

contract CurveStrategyAcricrypto3Mainnet is CurveStrategy {

  address public triCrypto_unused; // just a differentiator for the bytecode

  constructor() public {}


  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3);
    address gauge = address(0x3B6B158A76fd8ccc297538F454ce7B4787778c7C);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address crv = address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    address usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address aTriCrypto3CurveDeposit = address(0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8);
    CurveStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge, //rewardPool
      2, //depositArrayPosition
      aTriCrypto3CurveDeposit,
      usdt, //depositToken
      5,
      false
    );
    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[crv] = [crv, weth];
    WETH2deposit = [weth, usdt];
    rewardTokens = [crv, wmatic];
    useQuick[crv] = false;
    useQuick[wmatic] = false;
    useQuick[usdt] = false;
  }
}
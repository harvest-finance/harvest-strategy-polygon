//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CurveStrategy3Crypto.sol";

contract CurveStrategy3CryptoMainnet is CurveStrategy3Crypto {

  address public triCrypto_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8096ac61db23291252574D49f036f0f9ed8ab390);
    address gauge = address(0xb0a366b987d77b5eD5803cBd95C80bB6DEaB48C0);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address crv = address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address triCryptoCurveDeposit = address(0x3FCD5De6A9fC8A99995c406c77DDa3eD7E406f81);
    CurveStrategy3Crypto.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge, //rewardPool
      1, //depositArrayPosition
      triCryptoCurveDeposit,
      usdc //depositToken
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

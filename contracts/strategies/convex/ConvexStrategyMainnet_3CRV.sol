//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./base/ConvexStrategy.sol";

contract ConvexStrategyMainnet_3CRV is ConvexStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171); // Info -> LP Token address
    address rewardPool = address(0xf25958C64634FD5b5eb10539769aA6CAB355599A); // Info -> Rewards contract address
    address crv = address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    address cvx = address(0x4257EA7637c355F81616050CbB6a9b709fd72683);
    address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address curveDeposit = address(0x445FE580eF8d70FF569aB36e80c647af338db351);
    ConvexStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool, // rewardPool
      2,  // Pool id: Info -> Rewards contract address -> read -> pid
      usdc, // depositToken
      1, //depositArrayPosition. Find deposit transaction -> input params
      curveDeposit, // deposit contract: usually underlying. Find deposit transaction -> interacted contract
      3, //nTokens -> total number of deposit tokens
      false //metaPool -> if LP token address == pool address (at curve)
    );
    rewardTokens = [crv, cvx];
    reward2WETH[crv] = [crv, weth];
    reward2WETH[cvx] = [cvx, weth];
    WETH2deposit = [weth, usdc];
    storedPairFee[weth][usdc] = 500;
  }
}
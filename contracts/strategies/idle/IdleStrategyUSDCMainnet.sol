//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
import "./IdleFinanceStrategy.sol";

/**
* Adds the mainnet addresses to the PickleStrategy3Pool
*/
contract IdleStrategyUSDCMainnet is IdleFinanceStrategy {

  // token addresses
  address constant public __usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address constant public __idleUnderlying= address(0x1ee6470CD75D5686d0b2b90C0305Fa46fb0C89A1);
  address constant public __wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  constructor(
    address _storage,
    address _vault
  )
  IdleFinanceStrategy(
    _storage,
    __usdc,
    __idleUnderlying,
    _vault
  )
  public {
    rewardTokens = [__wmatic];
    reward2WETH[__wmatic] = [__wmatic, weth];
    WETH2underlying = [weth, __usdc];
    sell[__wmatic] = true;
    useQuick[__wmatic] = true;
    useQuick[__usdc] = true;
  }
}

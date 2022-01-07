//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
import "./IdleFinanceStrategy.sol";

/**
* Adds the mainnet addresses to the PickleStrategy3Pool
*/
contract IdleStrategyWETHMainnet is IdleFinanceStrategy {

  // token addresses
  address constant public __idleUnderlying= address(0xfdA25D931258Df948ffecb66b5518299Df6527C4);
  address constant public __wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  constructor(
    address _storage,
    address _vault
  )
  IdleFinanceStrategy(
    _storage,
    weth,
    __idleUnderlying,
    _vault
  )
  public {
    rewardTokens = [__wmatic];
    reward2WETH[__wmatic] = [__wmatic, weth];
    sell[__wmatic] = true;
    useQuick[__wmatic] = true;
  }
}

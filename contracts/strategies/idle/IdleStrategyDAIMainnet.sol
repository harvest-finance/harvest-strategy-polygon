//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
import "./IdleFinanceStrategy.sol";

/**
* Adds the mainnet addresses to the PickleStrategy3Pool
*/
contract IdleStrategyDAIMainnet is IdleFinanceStrategy {

  // token addresses
  address constant public __dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
  address constant public __idleUnderlying= address(0x8a999F5A3546F8243205b2c0eCb0627cC10003ab);
  address constant public __wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  constructor(
    address _storage,
    address _vault
  )
  IdleFinanceStrategy(
    _storage,
    __dai,
    __idleUnderlying,
    _vault
  )
  public {
    rewardTokens = [__wmatic];
    reward2WETH[__wmatic] = [__wmatic, weth];
    WETH2underlying = [weth, __dai];
    sell[__wmatic] = true;
    useQuick[__wmatic] = true;
    useQuick[__dai] = false;
  }
}

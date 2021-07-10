//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/sushi-base/MiniChefV2Strategy.sol";

contract SushiStrategyMainnet_MATIC_ETH is MiniChefV2Strategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address wmatic_weth = address(0xc4e595acDD7d12feC385E5dA5D43160e8A0bAC0E);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address sushi = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
    address miniChef = address(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    MiniChefV2Strategy.initializeBaseStrategy(
      _storage,
      wmatic_weth,
      _vault,
      miniChef,
      0,
      true
    );
    require(IVault(_vault).underlying() == wmatic_weth, "Underlying mismatch");

    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[sushi] = [sushi, weth];
    WETH2deposit[wmatic] = [weth, wmatic];
    rewardTokens = [sushi, wmatic];
    useQuick[sushi] = false;
    useQuick[wmatic] = true;
  }
}

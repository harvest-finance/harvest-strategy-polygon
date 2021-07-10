//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/sushi-base/MiniChefV2Strategy.sol";

contract SushiStrategyMainnet_USDT_ETH is MiniChefV2Strategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address weth_usdt = address(0xc2755915a85C6f6c1C0F3a86ac8C058F11Caa9C9);
    address usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address sushi = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
    address miniChef = address(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    MiniChefV2Strategy.initializeBaseStrategy(
      _storage,
      weth_usdt,
      _vault,
      miniChef,
      2,
      true
    );
    require(IVault(_vault).underlying() == weth_usdt, "Underlying mismatch");

    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[sushi] = [sushi, weth];
    WETH2deposit[usdt] = [weth, usdt];
    rewardTokens = [sushi, wmatic];
    useQuick[sushi] = false;
    useQuick[wmatic] = true;
    useQuick[usdt] = true;
  }
}

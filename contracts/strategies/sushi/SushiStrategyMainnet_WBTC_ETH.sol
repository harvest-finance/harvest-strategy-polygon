//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/interface/IVault.sol";
import "../../base/sushi-base/MiniChefV2Strategy.sol";

contract SushiStrategyMainnet_WBTC_ETH is MiniChefV2Strategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE62Ec2e799305E0D367b0Cc3ee2CdA135bF89816);
    address wbtc = address(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address sushi = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
    address miniChef = address(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    MiniChefV2Strategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      miniChef,
      3,
      true
    );
    require(IVault(_vault).underlying() == underlying, "Underlying mismatch");

    reward2WETH[wmatic] = [wmatic, weth];
    reward2WETH[sushi] = [sushi, weth];
    WETH2deposit[wbtc] = [weth, wbtc];
    rewardTokens = [sushi, wmatic];
    useQuick[sushi] = false;
    useQuick[wmatic] = true;
    useQuick[wbtc] = false;
  }
}

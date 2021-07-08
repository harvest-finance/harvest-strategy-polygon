//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/snx-base/SNXRewardUniLPStrategy.sol";

contract QuickStrategyMainnet_iFARM_QUICK is SNXRewardUniLPStrategy {

  address public ifarm = address(0xab0b2ddB9C7e440fAc8E140A89c0dbCBf2d7Bbff);
  address public ifarm_quick = address(0xD7668414BfD52DE6d59E16e5f647c9761992C435);
  address public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  address public SNXRewardPool = address(0xEa2EC0713D3B48234Ad4b2f14EDb4978D1228aE5);
  address public constant routerAddress = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  constructor(
    address _storage,
    address _vault
  )
  SNXRewardUniLPStrategy(_storage, ifarm_quick, _vault, SNXRewardPool, quick, routerAddress)
  public {
    require(IVault(_vault).underlying() == ifarm_quick, "Underlying mismatch");
    uniswapRoutes[ifarm] = [quick, ifarm];
  }
}

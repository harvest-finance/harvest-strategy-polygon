// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../inheritance/Governable.sol";
import "../../inheritance/OwnableWhitelist.sol";
import "../interface/IPoolFactory.sol";
import "../../PotPool.sol";

contract PotPoolFactory is OwnableWhitelist, IPoolFactory {
  address public iFARM = 0xab0b2ddB9C7e440fAc8E140A89c0dbCBf2d7Bbff;
  address public wMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  uint256 public poolDefaultDuration = 604800; // 7 days

  function setPoolDefaultDuration(uint256 _value) external onlyOwner {
    poolDefaultDuration = _value;
  }

  function deploy(address actualStorage, address vault) override external onlyWhitelisted returns (address) {
    address actualGovernance = Governable(vault).governance();

    string memory tokenSymbol = ERC20(vault).symbol();
    address[] memory rewardDistribution = new address[](1);
    rewardDistribution[0] = actualGovernance;
    address[] memory rewardTokens = new address[](2);
    rewardTokens[0] = iFARM;
    rewardTokens[1] = wMATIC;
    PotPool pool = new PotPool(
      rewardTokens,
      vault,
      poolDefaultDuration,
      rewardDistribution,
      actualStorage,
      string(abi.encodePacked("p", tokenSymbol)),
      string(abi.encodePacked("p", tokenSymbol)),
      18
    );

    Ownable(pool).transferOwnership(actualGovernance);

    return address(pool);
  }
}

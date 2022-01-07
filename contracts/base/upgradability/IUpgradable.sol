//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IUpgradeableStrategy {
  function scheduleUpgrade(address impl) external;
  function upgrade() external;
}

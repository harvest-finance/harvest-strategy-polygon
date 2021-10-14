//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IKyberRewardLocker {
  function vestCompletedSchedules(address token) external returns (uint256);
  function accountVestedBalance(address account, address token) external view returns(uint256);
  function accountEscrowedBalance(address account, address token) external view returns(uint256);
}

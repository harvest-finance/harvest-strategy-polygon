//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IKyberFairLaunch {
    function deposit(uint256 _pid, uint256 _amount, bool _shouldHarvest) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdrawAll(uint256 _pid) external;
    function emergencyWithdraw(uint256 _pid) external;
    function harvest(uint256 _pid) external;
    function getUserInfo(uint256 _pid, address _account) external view returns (uint256 amount, uint256[] memory unclaimedRewards, uint256[] memory lastRewardPerShares);
    function getPoolInfo(uint256 _pid) external view returns (uint256, address lpToken, uint32, uint32, uint32, uint256[] memory, uint256[] memory);
}

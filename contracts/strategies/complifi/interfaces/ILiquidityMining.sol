//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ILiquidityMining {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdrawEmergency(uint256 _pid) external;
    function userPoolInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
    function claim() external;
    function poolPidByAddress(address _address) external view returns (uint256 pid);
}

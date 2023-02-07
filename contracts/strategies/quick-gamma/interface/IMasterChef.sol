//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount, address _to) external;
    function withdraw(uint256 _pid, uint256 _amount, address _to) external;
    function emergencyWithdraw(uint256 _pid, address _to) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function lpToken(uint256 _pid) external view returns(address);
    function poolInfo(uint256 _pid) external view returns (uint256, uint256, uint256);
    function harvest(uint256 _pid, address _to) external;
}

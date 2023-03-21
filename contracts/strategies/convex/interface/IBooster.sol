//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;
    function depositAll(uint256 _pid) external;
    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external;
    function poolInfo(uint256 _pid) external view returns (address lpToken, address, address, bool, address);
    function earmarkRewards(uint256 _pid) external;
}

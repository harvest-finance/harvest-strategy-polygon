//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IExchange {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function claimReward() external;
}

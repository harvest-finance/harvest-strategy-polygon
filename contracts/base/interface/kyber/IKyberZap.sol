//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IKyberZap {
    function zapIn(address tokenIn, address tokenOut, uint256 userIn, address pool, address to, uint256 minLpQty, uint256 deadline) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IDMMFactory {
    function createPool(
        address tokenA,
        address tokenB,
        uint32 ampBps
    ) external returns (address pool);

    function setFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

    function setFeeToSetter(address) external;

    function getFeeConfiguration() external view returns (address feeTo, uint16 governmentFeeBps);

    function feeToSetter() external view returns (address);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function getUnamplifiedPool(address token0, address token1) external view returns (address);

    function getPools(address token0, address token1)
        external
        view
        returns (address[] memory _tokenPools);

    function isPool(
        address token0,
        address token1,
        address pool
    ) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IDesignatedPoolRegistry {
    function getDesignatedPool(address derivativeSpecification) external view returns (address);
}

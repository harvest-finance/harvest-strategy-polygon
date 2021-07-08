pragma solidity 0.6.12;

interface WMATIC {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

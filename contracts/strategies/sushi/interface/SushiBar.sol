pragma solidity 0.6.12;

interface SushiBar {
  function enter(uint256 _amount) external;
  function leave(uint256 _share) external;
}
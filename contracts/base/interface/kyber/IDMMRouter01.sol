//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
import "./IDMMExchangeRouter.sol";
import "./IDMMLiquidityRouter.sol";


/// @dev full interface for router
interface IDMMRouter01 is IDMMExchangeRouter, IDMMLiquidityRouter {
    function factory() external pure returns (address);

    function weth() external pure returns (address);
}

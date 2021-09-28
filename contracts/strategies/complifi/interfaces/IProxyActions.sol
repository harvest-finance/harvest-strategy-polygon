//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IProxyActions {
    function mintAndJoinPool(
      address _pool,
      uint256 _collateralAmount,
      address _tokenIn,
      uint256 _tokenAmountIn,
      address _tokenOut,
      uint256 _minAmountOut,
      uint256 _minPoolAmountOut
    ) external;
    function mintAndJoinPoolPermanent(
      address _plPool,
      uint256[] calldata _underlyingEndRoundHints,
      address _pool,
      uint256 _collateralAmount,
      address _tokenIn,
      uint256 _tokenAmountIn,
      address _tokenOut,
      uint256 _minAmountOut,
      uint256 _minPoolAmountOut
    ) external;
    function extractChange(address _pool) external;
    function removeLiquidityOnLiveOrMintingState(
      address _pool,
      uint256 _poolAmountIn,
      address _tokenIn,
      uint256 _tokenAmountIn,
      uint256 _minAmountOut,
      uint256[2] calldata _minAmountsOut
    ) external;
    function removeLiquidityOnLiveStatePermanent(
      address _plPool,
      uint256[] calldata _underlyingEndRoundHints,
      address _pool,
      uint256 _poolAmountIn,
      address _tokenIn,
      uint256 _tokenAmountIn,
      uint256 _minAmountOut,
      uint256[2] calldata _minAmountsOut
    ) external;
    function removeLiquidityOnSettledState(
      address _pool,
      uint256 _poolAmountIn,
      uint256[2] calldata _minAmountsOut,
      uint256[] calldata _underlyingEndRoundHints
    ) external;
    function rollover(
      address _poolSettled,
      uint256 _poolAmountIn,
      uint256[2] calldata _minAmountsOut,
      uint256[] calldata _underlyingEndRoundHints,
      address _poolNew,
      address _tokenIn,
      uint256 _tokenAmountIn,
      address _tokenOut,
      uint256 _minAmountOut,
      uint256 _minPoolAmountOut
    ) external;
    function rolloverPermanent(
      address _plPool,
      address _poolSettled,
      uint256 _poolAmountIn,
      uint256[2] calldata _minAmountsOut,
      uint256[] calldata _underlyingEndRoundHints,
      address _poolNew,
      address _tokenIn,
      uint256 _tokenAmountIn,
      address _tokenOut,
      uint256 _minAmountOut,
      uint256 _minPoolAmountOut
    ) external;
    function swapDerivativesToCollateral(
      address _plPool,
      uint256[] calldata _underlyingEndRoundHints,
      address _pool,
      address _derivativeIn,
      uint256 _derivativeAmount,
      uint256 _tokenAmountIn,
      address _derivativeOut,
      uint256 _derivativeMinAmountOut
    ) external;
    function withdraw(address _token) external;
    function withdrawAll(address[] calldata _tokens) external;
}

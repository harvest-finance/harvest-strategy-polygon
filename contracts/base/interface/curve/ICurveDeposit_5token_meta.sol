// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICurveDeposit_5token_meta {
  function add_liquidity(
    address pool,
    uint256[5] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    address pool,
    uint256[5] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    address pool,
    uint256 _amount,
    uint256[5] calldata amounts
  ) external;
}

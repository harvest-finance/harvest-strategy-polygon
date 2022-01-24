//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISavingsContract {
    function creditBalances(address) external view returns (uint256); // V1 & V2 (use balanceOf)

    /**
     * @dev Deposit the senders savings to the vault, and credit them internally with "credits".
     *      Credit amount is calculated as a ratio of deposit amount and exchange rate:
     *                    credits = underlying / exchangeRate
     *      We will first update the internal exchange rate by collecting any interest generated on the underlying.
     * @param _amount      Units of underlying to deposit into savings vault
     */
    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued); // V1 & V2


    /**
     * @dev Deposit the senders savings to the vault, and credit them internally with "credits".
     *      Credit amount is calculated as a ratio of deposit amount and exchange rate:
     *                    credits = underlying / exchangeRate
     *      We will first update the internal exchange rate by collecting any interest generated on the underlying.
     * @param _amount      Units of underlying to deposit into savings vault
     * @param _beneficiary     Immediately transfer the imUSD token to this beneficiary address
     */
    function depositSavings(uint256 _amount, address _beneficiary)
        external
        returns (uint256 creditsIssued); // V2

    /**
     * @dev Redeem specific number of the senders "credits" in exchange for underlying.
     *      Payout amount is calculated as a ratio of credits and exchange rate:
     *                    payout = credits * exchangeRate
     * @param _amount         Amount of credits to redeem
     */
    function redeemCredits(uint256 _amount) external returns (uint256 underlyingReturned); // V2
    
    /**
     * @dev Redeem credits into a specific amount of underlying.
     *      Credits needed to burn is calculated using:
     *                    credits = underlying / exchangeRate
     * @param _amount     Amount of underlying to redeem
     */
    function redeemUnderlying(uint256 _amount) external returns (uint256 creditsBurned); // V2

    function exchangeRate() external view returns (uint256); // V1 & V2
    
    /**
     * @dev Returns the underlying balance of a given user
     * @param _user     Address of the user to check
     */
    function balanceOfUnderlying(address _user) external view returns (uint256 underlying); // V2

    /**
     * @dev Converts a given underlying amount into credits
     * @param _underlying  Units of underlying
     */
    function underlyingToCredits(uint256 _underlying) external view returns (uint256 credits); // V2

    /**
     * @dev Converts a given credit amount into underlying
     * @param _credits  Units of credits
     */
    function creditsToUnderlying(uint256 _credits) external view returns (uint256 underlying); // V2

    function underlying() external view returns (IERC20 underlyingMasset); // V2
}
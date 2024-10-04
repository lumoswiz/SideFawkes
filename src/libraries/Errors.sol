// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

library Errors {
    /**
     * @notice Thrown when an auction hash has already been made.
     */
    error AuctionHashAlreadyMade(bytes32 auctionHash);

    /**
     * @notice Thrown when a caller is not a stated proposer.
     */
    error CallerNotProposer(address proposer);

    /**
     * @notice Thrown when a caller is not the beneficiary.
     */
    error CallerNotBeneficiary();

    /**
     * @notice Thrown when the auction has not been made.
     */
    error AuctionNotMade(bytes32 auctionHash);

    /**
     * @notice Thrown when the auction start time is in the past.
     */
    error InvalidAuctionStartTime(uint40 time);

    /**
     * @notice Thrown when the auction duration is equal to zero or greater than the maximum duration.
     */
    error InvalidAuctionDuration(uint40 duration);

    /**
     * @notice Thrown when the auction is not on.
     */
    error AuctionNotOn();

    /**
     * @notice Thrown when the auction is already on.
     */
    error AuctionIsOn();

    /**
     * @notice Thrown when the beneficiary has already claimed the ERC-721 asset.
     */
    error AlreadyClaimed();

    /**
     * @notice Thrown when the caller is the beneficiary.
     */
    error BeneficiaryCannotWithdraw();

    /**
     * @notice Thrown when the auction' proposer has already withdrawn their shielded ERC-20 tokens.
     */
    error AlreadyWithdrawn();
}

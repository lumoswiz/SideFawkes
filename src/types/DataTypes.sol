// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { inEuint128, euint128 } from "@fhenixprotocol/contracts/FHE.sol";

library Auction {
    /**
     * @notice Struct definining terms of an Auction.
     * @param startTIme Start time in seconds (unix timestamp).
     * @param proposer Address of the proposer.
     * @param duration Auction duration in seconds.
     * @param assetAddress Address of the ERC-721 asset to be put up for auction.
     * @param tokenId The token id of the ERC-721 asset.
     * @param reservePrice The encrypted reserve price for the ERC-721 asset.
     */
    struct Details {
        uint40 startTime;
        address proposer;
        uint40 duration;
        address assetAddress;
        uint256 tokenId;
        inEuint128 reservePrice;
    }

    /**
     * @notice Struct definining the two highest bids in an auction.
     * @dev Bids are denominated in amount of shielded ERC-20 tokens.
     * @param bid1 The encrypted highest bid.
     * @param bid2 The encrypted second highest bid.
     */
    struct Bids {
        euint128 bid1;
        euint128 bid2;
    }
}

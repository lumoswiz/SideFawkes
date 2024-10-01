// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { FHE, euint128 } from "@fhenixprotocol/contracts/FHE.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract Calculations {
    /// @dev Helper function that calculates the unencrypted bid difference between the callers previous and new bid.
    /// @dev Should revert on underflow.
    function calculateBidDiff(uint256 newBid, uint256 previousBid) internal pure returns (uint256) {
        return newBid - previousBid;
    }

    /// @dev Helper function that calculates the encrypted bid difference for a caller.
    function calculateCypherBidDiff(uint256 newBid, euint128 cypherPreviousBid) internal pure returns (euint128) {
        euint128 cypherNewBid = FHE.asEuint128(newBid);
        return cypherNewBid.sub(cypherPreviousBid);
    }
}

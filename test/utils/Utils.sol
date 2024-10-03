// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { Auction } from "src/types/DataTypes.sol";

import { Test } from "forge-std/src/Test.sol";
import { FHE, euint128, inEuint128, inEaddress, inEbool } from "@fhenixprotocol/contracts/FHE.sol";
import { MockFheOps } from "@fhenixprotocol/contracts/utils/debug/MockFheOps.sol";

import { Constants } from "test/utils/Constants.sol";
import { FheHelper } from "test/utils/FheHelper.sol";
import { Params } from "test/utils/Types.sol";

contract Utils is Constants, Test {
    /*----------------------------------------------------------*|
    |*  # FHE OPS                                               *|
    |*----------------------------------------------------------*/

    function initializeFhe() public {
        MockFheOps fheos = new MockFheOps();
        bytes memory code = address(fheos).code;
        vm.etch(address(128), code);
    }

    function encrypt(uint256 amount) internal pure returns (euint128) {
        return FHE.asEuint128(amount);
    }

    /*----------------------------------------------------------*|
    |*  # CHEATCODE UTILITIES                                   *|
    |*----------------------------------------------------------*/

    /// @dev Bounds a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal pure returns (uint40) {
        return uint40(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(block.timestamp);
    }

    /// @dev Stops the active prank and sets a new one.
    function resetPrank(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }

    /*----------------------------------------------------------*|
    |*  # OTHER UTILITIES                                       *|
    |*----------------------------------------------------------*/

    function generatePk(string memory name) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(name)));
    }

    function proposer() internal pure returns (address) {
        return vm.addr(generatePk("proposer"));
    }

    function assetAddress() internal pure returns (address) {
        return ASSET;
    }

    /*----------------------------------------------------------*|
    |*  # FUZZERS                                               *|
    |*----------------------------------------------------------*/

    /// @dev Fuzzes the auction details with defaults for: proposer, tokenId and assetAddress.
    function fuzzAuctionDetails(Params memory params) internal view returns (Auction.Details memory) {
        // Bound start time
        params.startTime = boundUint40(params.startTime, getBlockTimestamp() + 1, MAX_UNIX_TIMESTAMP - MAX_DURATION);

        // Bound duration - non-zero, up to max duration
        params.duration = boundUint40(params.duration, 1, MAX_DURATION);

        // Bound reserve price
        params.reservePrice = bound(params.reservePrice, 0, BID2 - 1);

        // Encrypt reserve price
        inEuint128 memory encryptedRp = FheHelper.encrypt128(params.reservePrice);

        return Auction.Details({
            startTime: params.startTime,
            proposer: proposer(),
            duration: params.duration,
            assetAddress: assetAddress(),
            tokenId: TOKEN_ID,
            reservePrice: encryptedRp
        });
    }
}

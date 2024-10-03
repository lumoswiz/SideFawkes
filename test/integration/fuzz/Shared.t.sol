// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "test/Base.t.sol";
import { Auction } from "src/types/DataTypes.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract Shared_Integration_Test is Base_Test {
    /*----------------------------------------------------------*|
    |*  # HELPERS                                               *|
    |*----------------------------------------------------------*/

    function setupAuctionSuccess(Params memory params, uint40 time, uint256 bid) internal returns (bytes memory) {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time when the auction is on
        vm.warp(details.startTime + 1);

        // Bid values

        // Setting up bids - alice is highest bid & clear reserve price
        resetPrank(users.bob);
        auction.bid(auctionData, FheHelper.encrypt128(BID2));

        resetPrank(users.charlee);
        auction.bid(auctionData, FheHelper.encrypt128(RESERVE_PRICE));

        bid = bound(bid, BID1, INITIAL_BALANCE);
        resetPrank(users.alice);
        auction.bid(auctionData, FheHelper.encrypt128(bid));

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        return auctionData;
    }
}

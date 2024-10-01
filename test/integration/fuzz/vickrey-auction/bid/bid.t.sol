// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "test/Base.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { inEuint128 } from "@fhenixprotocol/contracts/FHE.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract Bid_Unit_Fuzz_Test is Base_Test {
    function setUp() public override {
        super.setUp();

        // Alice is the default caller of this suite
        vm.startPrank(users.alice);
    }

    function testFuzz_shouldFail_AuctionNotMade(Params memory params) external {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);
        inEuint128 memory amount = FheHelper.encrypt128(0);

        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionNotMade.selector, keccak256(auctionData)));
        auction.bid(auctionData, amount);
    }

    modifier whenAuctionMade() {
        _;
    }

    function testFuzz_shouldFail_BeforeTheAuction(Params memory params) external whenAuctionMade {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);
        inEuint128 memory amount = FheHelper.encrypt128(0);

        // Create the auction
        createAuction(details);

        // Reset prank
        resetPrank(users.alice);

        // Require before start time
        require(getBlockTimestamp() < details.startTime);

        // Try to bid
        vm.expectRevert(Errors.AuctionNotOn.selector);
        auction.bid(auctionData, amount);
    }

    function testFuzz_shouldFail_AfterAuction(Params memory params, uint256 time) external whenAuctionMade {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);
        inEuint128 memory amount = FheHelper.encrypt128(0);

        // Create the auction
        createAuction(details);

        // Reset prank
        resetPrank(users.alice);

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        // Try to bid
        vm.expectRevert(Errors.AuctionNotOn.selector);
        auction.bid(auctionData, amount);
    }

    /*----------------------------------------------------------*|
    |*  # CALLER HAS NO PREVIOUS BIDS                           *|
    |*----------------------------------------------------------*/

    modifier whenAuctionOn() {
        _;
    }

    modifier givenWhenCallerNoPreviousBid() {
        _;
    }

    function testFuzz_shouldFail_ZeroBid(
        Params memory params,
        uint40 time
    )
        external
        whenAuctionMade
        whenAuctionOn
        givenWhenCallerNoPreviousBid
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);
        inEuint128 memory amount = FheHelper.encrypt128(0);

        // Create the auction
        createAuction(details);

        // Reset prank
        resetPrank(users.alice);

        // Warp to a time when the auction is on
        time = boundUint40(time, details.startTime, details.startTime + details.duration);
        vm.warp(time);

        // Try to bid
        vm.expectRevert("MockFheOps: req");
        auction.bid(auctionData, amount);
    }
}

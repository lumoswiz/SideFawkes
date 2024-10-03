// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "test/Base.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { FHE, inEuint128 } from "@fhenixprotocol/contracts/FHE.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract ClaimSuccess_Unit_Fuzz_Test is Base_Test {
    function setUp() public override {
        super.setUp();

        // Alice is the default caller of this suite
        vm.startPrank(users.alice);
    }

    function testFuzz_ShouldFail_AuctionNotMade(Params memory params) external {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionNotMade.selector, keccak256(auctionData)));
        auction.claimSuccess(auctionData);
    }

    modifier givenWhenAuctionMade() {
        _;
    }

    function testFuzz_ShouldFail_AuctionIsOn(Params memory params) external givenWhenAuctionMade {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Reset prank
        resetPrank(users.alice);

        // Try to withdraw
        vm.expectRevert(Errors.AuctionIsOn.selector);
        auction.claimSuccess(auctionData);
    }

    modifier whenAuctionIsFinished() {
        _;
    }

    function testFuzz_ShouldFail_CallerIsNotBeneficiary(
        Params memory params,
        uint40 time
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        // Reset prank
        resetPrank(users.alice);

        // Try to withdraw
        vm.expectRevert(Errors.CallerNotBeneficiary.selector);
        auction.claimSuccess(auctionData);
    }

    modifier whenCallerIsBeneficiary() {
        _;
    }

    function testFuzz_ShouldFail_AssetAlreadyClaimed(
        Params memory params,
        uint40 time
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsBeneficiary
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        // Reset prank
        resetPrank(users.alice);

        // Set alice as the beneficiary
        bytes32 auctionHash = keccak256(abi.encode(details));
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_BENEFICIARY));
        vm.store(address(auction), slot, bytes32(uint256(uint160(users.alice)))); // value should be alice's address

        // Set already claimed
        slot = keccak256(abi.encode(auctionHash, SLOT_CLAIMED));
        vm.store(address(auction), slot, bytes32(uint256(1))); // value should be 1 (== true)

        // Try to withdraw
        vm.expectRevert(Errors.AlreadyClaimed.selector);
        auction.claimSuccess(auctionData);
    }

    modifier givenWhenAssetNotClaimed() {
        _;
    }

    function testFuzz_ShouldFail_BelowReservePrice(
        Params memory params,
        uint40 time
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsBeneficiary
        givenWhenAssetNotClaimed
    {
        vm.assume(params.reservePrice > 0); // Non-zero reserve price
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        // Reset prank
        resetPrank(users.alice);

        // Set alice as the beneficiary
        bytes32 auctionHash = keccak256(abi.encode(details));
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_BENEFICIARY));
        vm.store(address(auction), slot, bytes32(uint256(uint160(users.alice)))); // value should be alice's address

        // Try to withdraw
        vm.expectRevert("MockFheOps: req");
        auction.claimSuccess(auctionData);
    }

    modifier whenGtEqReservePrice() {
        _;
    }

    function testFuzz_ClaimSuccess(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsBeneficiary
        givenWhenAssetNotClaimed
        whenGtEqReservePrice
    {
        (Auction.Details memory details, bytes memory auctionData) = setupAuctionSuccess(params, time, bid);

        bytes32 h = keccak256(auctionData);
        (uint256 actualB1, uint256 actualB2) = getHighestBids(h);
        uint256 aliceBid = getBidPerAddr(h, users.alice);
        uint256 bobBid = getBidPerAddr(h, users.bob);
        uint256 charleeBid = getBidPerAddr(h, users.charlee);

        emit log_named_uint("actualB1", actualB1);
        emit log_named_uint("actualB2", actualB2);
        emit log_named_uint("aliceBid", aliceBid);
        emit log_named_uint("bobBid", bobBid);
        emit log_named_uint("charleeBid", charleeBid);
        emit log_named_uint("reserve price", FHE.decrypt(FHE.asEuint128(details.reservePrice)));

        // Alice claims asset
        auction.claimSuccess(auctionData);
    }

    /*----------------------------------------------------------*|
    |*  # HELPERS                                               *|
    |*----------------------------------------------------------*/

    function setupAuctionSuccess(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        internal
        returns (Auction.Details memory, bytes memory)
    {
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

        return (details, auctionData);
    }
}

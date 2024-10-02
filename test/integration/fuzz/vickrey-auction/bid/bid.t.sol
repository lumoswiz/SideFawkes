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

    function testFuzz_ShouldFail_AuctionNotMade(Params memory params) external {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);
        inEuint128 memory amount = FheHelper.encrypt128(0);

        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionNotMade.selector, keccak256(auctionData)));
        auction.bid(auctionData, amount);
    }

    modifier whenAuctionMade() {
        _;
    }

    function testFuzz_ShouldFail_BeforeTheAuction(Params memory params) external whenAuctionMade {
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

    function testFuzz_ShouldFail_AfterAuction(Params memory params, uint256 time) external whenAuctionMade {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);
        inEuint128 memory amount = FheHelper.encrypt128(0);

        // Create the auction
        createAuction(details);

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        // Reset prank
        resetPrank(users.alice);

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

    function testFuzz_ShouldFail_ZeroBid(
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

        // Warp to a time when the auction is on
        time = boundUint40(time, details.startTime, details.startTime + details.duration);
        vm.warp(time);

        // Reset prank
        resetPrank(users.alice);

        // Try to bid
        vm.expectRevert("MockFheOps: req");
        auction.bid(auctionData, amount);
    }

    modifier whenBidGtZero() {
        _;
    }

    function testFuzz_Bid_0(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        whenAuctionMade
        whenAuctionOn
        givenWhenCallerNoPreviousBid
        whenBidGtZero
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);
        bid = bound(bid, 1, INITIAL_BALANCE);
        inEuint128 memory amount = FheHelper.encrypt128(bid);

        // Create the auction
        createAuction(details);

        // Warp to a time when the auction is on
        time = boundUint40(time, details.startTime, details.startTime + details.duration);
        vm.warp(time);

        // Cached values
        uint256 alice_originalBalance = decryptedTokenBalance(users.alice);
        uint256 auction_originalBalance = decryptedTokenBalance(address(auction));

        // Reset prank
        resetPrank(users.alice);

        // Bid
        auction.bid(auctionData, amount);

        // Assert that the encrypted bid value has been transferred from the caller to the contract
        assertEq(decryptedTokenBalance(users.alice), alice_originalBalance - bid, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_originalBalance + bid, "balanceOfEncrypted");

        // Assert that the bidPerAddr is updated for the caller
        assertEq(getBidPerAddr(keccak256(auctionData), users.alice), bid, "bidPerAddr");
    }

    modifier givenWhenBidLtEqSecondHighestBid() {
        _;
    }

    function testFuzz_Bid_1(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        whenAuctionMade
        whenAuctionOn
        givenWhenCallerNoPreviousBid
        whenBidGtZero
        givenWhenBidLtEqSecondHighestBid
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time when the auction is on
        time = boundUint40(time, details.startTime, details.startTime + details.duration);
        vm.warp(time);

        // Setting up highest bids
        resetPrank(users.bob);
        auction.bid(auctionData, FheHelper.encrypt128(BID1));

        resetPrank(users.charlee);
        auction.bid(auctionData, FheHelper.encrypt128(BID2));

        // Cached state
        bytes32 auctionHash = keccak256(auctionData);
        (uint256 expectedBid1, uint256 expectedBid2) = getHighestBids(auctionHash);
        address expectedBeneficiary = getBeneficiary(auctionHash);
        uint256 alice_originalBalance = decryptedTokenBalance(users.alice);
        uint256 auction_originalBalance = decryptedTokenBalance(address(auction));

        // Alice bids below the second highest bid
        bid = bound(bid, 1, BID2);
        resetPrank(users.alice);
        auction.bid(auctionData, FheHelper.encrypt128(bid));

        // Assert that the second and highest bids are unchanged after alice's bid
        (uint256 actualBid1, uint256 actualBid2) = getHighestBids(auctionHash);
        assertEq(actualBid1, expectedBid1, "highest bid");
        assertEq(actualBid2, expectedBid2, "second highest bid");

        // Assert that the beneficiary is unchanged after alice's bid
        assertEq(getBeneficiary(auctionHash), expectedBeneficiary, "beneficiary");

        // Assert that the encrypted bid value has been transferred from alice to the contract
        assertEq(decryptedTokenBalance(users.alice), alice_originalBalance - bid, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_originalBalance + bid, "balanceOfEncrypted");

        // Assert that the bidPerAddr is updated for alice
        assertEq(getBidPerAddr(keccak256(auctionData), users.alice), bid, "bidPerAddr");
    }

    modifier givenWhenBidGtSecondHighestBid() {
        _;
    }

    modifier givenWhenBidLtEqHighestBid() {
        _;
    }

    function testFuzz_Bid_2(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        whenAuctionMade
        whenAuctionOn
        givenWhenCallerNoPreviousBid
        whenBidGtZero
        givenWhenBidGtSecondHighestBid
        givenWhenBidLtEqHighestBid
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time when the auction is on
        time = boundUint40(time, details.startTime, details.startTime + details.duration);
        vm.warp(time);

        // Setting up highest bids
        resetPrank(users.bob);
        auction.bid(auctionData, FheHelper.encrypt128(BID1));

        resetPrank(users.charlee);
        auction.bid(auctionData, FheHelper.encrypt128(BID2));

        // Cached state
        bytes32 auctionHash = keccak256(auctionData);
        (uint256 expectedBid1,) = getHighestBids(auctionHash);
        address expectedBeneficiary = getBeneficiary(auctionHash);
        uint256 alice_originalBalance = decryptedTokenBalance(users.alice);
        uint256 auction_originalBalance = decryptedTokenBalance(address(auction));

        // Alice bids above the second highest bid & at most the highest bid
        bid = bound(bid, BID2 + 1, BID1);
        resetPrank(users.alice);
        auction.bid(auctionData, FheHelper.encrypt128(bid));

        // Assert that the second highest bid is updated & the highest remains unchanged
        (uint256 actualBid1, uint256 actualBid2) = getHighestBids(auctionHash);
        assertEq(actualBid1, expectedBid1, "highest bid");
        assertEq(actualBid2, bid, "second highest bid");

        // Assert that the beneficiary is unchanged after alice's bid
        assertEq(getBeneficiary(auctionHash), expectedBeneficiary, "beneficiary");

        // Assert that the encrypted bid value has been transferred from alice to the contract
        assertEq(decryptedTokenBalance(users.alice), alice_originalBalance - bid, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_originalBalance + bid, "balanceOfEncrypted");

        // Assert that the bidPerAddr is updated for alice
        assertEq(getBidPerAddr(keccak256(auctionData), users.alice), bid, "bidPerAddr");
    }

    modifier givenWhenBidGtHighestBid() {
        _;
    }

    function testFuzz_Bid_3(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        whenAuctionMade
        whenAuctionOn
        givenWhenCallerNoPreviousBid
        whenBidGtZero
        givenWhenBidGtSecondHighestBid
        givenWhenBidGtHighestBid
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time when the auction is on
        time = boundUint40(time, details.startTime, details.startTime + details.duration);
        vm.warp(time);

        // Setting up highest bids
        resetPrank(users.bob);
        auction.bid(auctionData, FheHelper.encrypt128(BID1));

        resetPrank(users.charlee);
        auction.bid(auctionData, FheHelper.encrypt128(BID2));

        // Cached state
        bytes32 auctionHash = keccak256(auctionData);
        (, uint256 expectedBid2) = getHighestBids(auctionHash);
        uint256 alice_originalBalance = decryptedTokenBalance(users.alice);
        uint256 auction_originalBalance = decryptedTokenBalance(address(auction));

        // Alice bids above the highest bid & up to their encrypted token balance
        bid = bound(bid, BID1 + 1, INITIAL_BALANCE);
        resetPrank(users.alice);
        auction.bid(auctionData, FheHelper.encrypt128(bid));

        // Assert that the second highest bid is unchanged & the highest bid is updated
        (uint256 actualBid1, uint256 actualBid2) = getHighestBids(auctionHash);
        assertEq(actualBid1, bid, "highest bid");
        assertEq(actualBid2, expectedBid2, "second highest bid");

        // Assert that the beneficiary is now alice
        assertEq(getBeneficiary(auctionHash), users.alice, "beneficiary");

        // Assert that the encrypted bid value has been transferred from alice to the contract
        assertEq(decryptedTokenBalance(users.alice), alice_originalBalance - bid, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_originalBalance + bid, "balanceOfEncrypted");

        // Assert that the bidPerAddr is updated for alice
        assertEq(getBidPerAddr(keccak256(auctionData), users.alice), bid, "bidPerAddr");
    }
}

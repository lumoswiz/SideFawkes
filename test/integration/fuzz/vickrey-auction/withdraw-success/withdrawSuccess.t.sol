// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Shared_Integration_Test } from "test/integration/fuzz/Shared.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract WithdrawSuccess_Integration_Fuzz_Test is Shared_Integration_Test {
    function setUp() public override {
        super.setUp();

        // Proposer is the default caller of this suite
        vm.startPrank(users.proposer);
    }

    function testFuzz_ShouldFail_AuctionNotMade(Params memory params) external {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionNotMade.selector, keccak256(auctionData)));
        auction.withdrawSuccess(auctionData);
    }

    modifier givenWhenAuctionMade() {
        _;
    }

    function testFuzz_ShouldFail_AuctionIsOn(Params memory params) external givenWhenAuctionMade {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Try to withdraw
        vm.expectRevert(Errors.AuctionIsOn.selector);
        auction.withdrawSuccess(auctionData);
    }

    modifier whenAuctionIsFinished() {
        _;
    }

    function testFuzz_ShouldFail_CallerIsNotProposer(
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

        // Reset prank to anyone but the proposer
        resetPrank(users.alice);

        // Try to withdraw
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotProposer.selector, details.proposer));
        auction.withdrawSuccess(auctionData);
    }

    modifier whenCallerIsProposer() {
        _;
    }

    function testFuzz_ShouldFail_AssetAlreadyWithdrawn(
        Params memory params,
        uint40 time
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsProposer
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        // Set already withdrawn
        bytes32 slot = keccak256(abi.encode(keccak256(auctionData), SLOT_WITHDRAWN));
        vm.store(address(auction), slot, bytes32(uint256(1))); // value should be 1 (== true)

        // Try to withdraw
        vm.expectRevert(Errors.AlreadyWithdrawn.selector);
        auction.withdrawSuccess(auctionData);
    }

    modifier givenWhenTokensNotWithdrawn() {
        _;
    }

    function testFuzz_ShouldFail_BelowReservePrice(
        Params memory params,
        uint40 time
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsProposer
        givenWhenTokensNotWithdrawn
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

        // Try to withdraw
        vm.expectRevert();
        auction.withdrawSuccess(auctionData);
    }

    modifier whenGtEqReservePrice() {
        _;
    }

    function testFuzz_WithdrawSuccess(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsProposer
        givenWhenTokensNotWithdrawn
        whenGtEqReservePrice
    {
        bytes memory auctionData = setupAuctionSuccess(params, time, bid); // alice is caller from here
        bytes32 auctionHash = keccak256(auctionData);

        // Reset prank to proposer
        resetPrank(users.proposer);

        // Cached state
        uint256 proposer_beforeBalance = decryptedTokenBalance(users.proposer);
        uint256 auction_beforeBalance = decryptedTokenBalance(address(auction));

        // Proposer withdraws tokens
        auction.withdrawSuccess(auctionData);

        // Assert that withdrawn is now true
        assertEq(getWithdrawn(auctionHash), true, "withdrawn");

        // Assert that the second highest bid encrypted value is transferred to the proposer
        (, uint256 bid2) = getHighestBids(auctionHash);
        assertEq(decryptedTokenBalance(users.proposer), proposer_beforeBalance + bid2, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_beforeBalance - bid2, "balanceOfEncrypted");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Shared_Integration_Test } from "test/integration/fuzz/Shared.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract WithdrawFail_Unit_Fuzz_Test is Shared_Integration_Test {
    function setUp() public override {
        super.setUp();

        // Proposer is the default caller of this suite
        vm.startPrank(users.proposer);
    }

    function testFuzz_ShouldFail_AuctionNotMade(Params memory params) external {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionNotMade.selector, keccak256(auctionData)));
        auction.withdrawFail(auctionData);
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
        auction.withdrawFail(auctionData);
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
        auction.withdrawFail(auctionData);
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
        auction.withdrawFail(auctionData);
    }

    modifier givenWhenTokensNotWithdrawn() {
        _;
    }

    function testFuzz_ShouldFail_AboveReservePrice(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsProposer
        givenWhenTokensNotWithdrawn
    {
        bytes memory auctionData = setupAuctionSuccess(params, time, bid); // Alice is caller from here

        // Reset prank
        resetPrank(users.proposer);

        // Try to withdraw
        vm.expectRevert("MockFheOps: req");
        auction.withdrawFail(auctionData);
    }

    modifier whenLtEqReservePrice() {
        _;
    }

    function testFuzz_WithdrawFailed(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsProposer
        givenWhenTokensNotWithdrawn
        whenLtEqReservePrice
    {
        bytes memory auctionData = setupAuctionFailed(params, time, bid); // alice is caller from here
        bytes32 auctionHash = keccak256(auctionData);

        // Reset prank to proposer
        resetPrank(users.proposer);

        // Cached state
        uint256 proposer_beforeBalance = decryptedTokenBalance(users.proposer);
        uint256 auction_beforeBalance = decryptedTokenBalance(address(auction));

        // Proposer withdraws tokens
        auction.withdrawFail(auctionData);

        // Assert that withdrawn is now true
        assertEq(getWithdrawn(auctionHash), true, "withdrawn");

        // Assert that the encrypted balances of the proposer and auction do not change.
        assertEq(decryptedTokenBalance(users.proposer), proposer_beforeBalance, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_beforeBalance, "balanceOfEncrypted");

        // Assert that the asset is returned to the proposer
        assertEq(asset.ownerOf(TOKEN_ID), users.proposer, "ownerOf");
    }
}

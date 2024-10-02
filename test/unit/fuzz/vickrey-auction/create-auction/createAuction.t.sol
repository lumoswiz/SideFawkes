// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "test/Base.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

contract CreateAuction_Unit_Fuzz_Test is Base_Test {
    function setUp() public override {
        super.setUp();

        // Make the proposer the default caller of this test suite
        vm.startPrank(users.proposer);
    }

    function testFuzz_ShouldFail_AuctionHashHasBeenMade(Auction.Details memory details) external {
        // Store the auction hash in the contract
        bytes32 auctionHash = keccak256(abi.encode(details));
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_AUCTIONS_MADE));
        vm.store(address(auction), slot, bytes32(uint256(1))); // value should be true

        // Try to create the auction
        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionHashAlreadyMade.selector, auctionHash));
        auction.createAuction(details);
    }

    modifier whenAuctionNotMade() {
        _;
    }

    function testFuzz_ShouldFail_CallerNotProposer(Auction.Details memory details) external whenAuctionNotMade {
        vm.assume(details.proposer != users.proposer);

        // Try to create the auction
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerIsNotStatedProposer.selector, details.proposer));
        auction.createAuction(details);
    }

    modifier whenCallerIsProposer() {
        _;
    }

    function testFuzz_ShouldFail_StartTimeInThePast(Auction.Details memory details)
        external
        whenAuctionNotMade
        whenCallerIsProposer
    {
        details.proposer = users.proposer; // Set caller as proposer
        vm.assume(details.startTime < block.timestamp);

        // Try to create the auction
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAuctionStartTime.selector, details.startTime));
        auction.createAuction(details);
    }

    modifier whenStartTimeValid() {
        _;
    }

    function testFuzz_ShouldFail_DurationGtMax(Auction.Details memory details)
        external
        whenAuctionNotMade
        whenCallerIsProposer
        whenStartTimeValid
    {
        // Set 'passing' vars
        details.proposer = users.proposer;
        vm.assume(details.startTime >= block.timestamp);
        // Set 'failing' vars
        vm.assume(details.duration > auction.MAXIMUM_DURATION());

        // Try to create the auction
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAuctionDuration.selector, details.duration));
        auction.createAuction(details);
    }

    modifier whenDurationValid() {
        _;
    }

    function testFuzz_CreateAuction(Auction.Details memory details)
        external
        whenAuctionNotMade
        whenCallerIsProposer
        whenStartTimeValid
        whenDurationValid
    {
        // Set 'passing' vars
        details.proposer = users.proposer;
        details.assetAddress = address(asset);
        details.tokenId = defaults.TOKEN_ID();
        vm.assume(details.startTime >= block.timestamp);
        vm.assume(details.duration <= auction.MAXIMUM_DURATION());

        // Expect emit
        vm.expectEmit();
        emit VaultPull(address(asset), details.tokenId, users.proposer);

        // Create the auction
        auction.createAuction(details);

        // Assert that the owner of the asset tokenId is now the auction contract
        assertEq(asset.ownerOf(details.tokenId), address(auction), "ownerOf");

        // Assert that the auction is made
        bytes32 auctionHash = keccak256(abi.encode(details));
        assertEq(getAuctionsMade(auctionHash), true, "auctionsMade");
    }
}

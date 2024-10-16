// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Shared_Integration_Test } from "test/integration/fuzz/Shared.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract ClaimSuccess_Integration_Fuzz_Test is Shared_Integration_Test {
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
        vm.expectRevert();
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
        bytes memory auctionData = setupAuctionSuccess(params, time, bid);
        bytes32 auctionHash = keccak256(auctionData);

        // Cached state
        uint256 alice_beforeBalance = decryptedTokenBalance(users.alice);
        uint256 auction_beforeBalance = decryptedTokenBalance(address(auction));

        // Alice claims asset
        auction.claimSuccess(auctionData);

        // Assert that claimed is now true
        assertEq(getClaimed(auctionHash), true, "claimed");

        // Assert that the difference in encrypted value of the highest and second highest bids is transferred to caller
        (uint256 bid1, uint256 bid2) = getHighestBids(auctionHash);
        assertEq(decryptedTokenBalance(users.alice), alice_beforeBalance + (bid1 - bid2), "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_beforeBalance - (bid1 - bid2), "balanceOfEncrypted");

        // Assert that the NFT asset has been transferred to the beneficiary/alice
        assertEq(asset.ownerOf(TOKEN_ID), users.alice, "ownerOf");
    }
}

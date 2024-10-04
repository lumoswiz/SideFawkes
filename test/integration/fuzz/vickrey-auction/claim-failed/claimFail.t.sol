// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Shared_Integration_Test } from "test/integration/fuzz/Shared.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract ClaimFail_Unit_Fuzz_Test is Shared_Integration_Test {
    function setUp() public override {
        super.setUp();

        // Alice is the default caller of this suite
        vm.startPrank(users.alice);
    }

    function testFuzz_ShouldFail_AuctionNotMade(Params memory params) external {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionNotMade.selector, keccak256(auctionData)));
        auction.claimFail(auctionData);
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
        auction.claimFail(auctionData);
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
        auction.claimFail(auctionData);
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
        auction.claimFail(auctionData);
    }

    modifier givenWhenAssetNotClaimed() {
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
        whenCallerIsBeneficiary
        givenWhenAssetNotClaimed
    {
        bytes memory auctionData = setupAuctionSuccess(params, time, bid);

        // Try to claimFailed for a successful auction
        vm.expectRevert("MockFheOps: req");
        auction.claimFail(auctionData);
    }

    modifier whenLtEqReservePrice() {
        _;
    }

    function testFuzz_ClaimFailed(
        Params memory params,
        uint40 time,
        uint256 bid
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerIsBeneficiary
        givenWhenAssetNotClaimed
        whenLtEqReservePrice
    {
        bytes memory auctionData = setupAuctionFailed(params, time, bid); // alice is caller from here
        bytes32 auctionHash = keccak256(auctionData);

        // Cached state
        address beneficiary = getBeneficiary(auctionHash);
        uint256 beneficiary_beforeBalance = decryptedTokenBalance(beneficiary);
        uint256 beneficiary_bid = getBidPerAddr(auctionHash, beneficiary);
        uint256 auction_beforeBalance = decryptedTokenBalance(address(auction));

        // Beneficiary claims tokens from failed auction
        resetPrank(beneficiary);
        auction.claimFail(auctionData);

        // Assert that claimed is now true
        assertEq(getClaimed(auctionHash), true, "claimed");

        // Assert that alice's encrypted bid is returned
        assertEq(decryptedTokenBalance(beneficiary), beneficiary_beforeBalance + beneficiary_bid, "balanceOfEncrypted");
        assertEq(beneficiary_beforeBalance + beneficiary_bid, INITIAL_BALANCE, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_beforeBalance - beneficiary_bid, "balanceOfEncrypted");
    }
}

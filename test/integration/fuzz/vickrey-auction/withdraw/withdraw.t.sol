// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "test/Base.t.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { inEuint128 } from "@fhenixprotocol/contracts/FHE.sol";

import { Params } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract Withdraw_Integration_Fuzz_Test is Base_Test {
    function setUp() public override {
        super.setUp();

        // Alice is the default caller of this suite
        vm.startPrank(users.alice);
    }

    function testFuzz_ShouldFail_AuctionNotMade(Params memory params) external {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        vm.expectRevert(abi.encodeWithSelector(Errors.AuctionNotMade.selector, keccak256(auctionData)));
        auction.withdraw(auctionData);
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
        auction.withdraw(auctionData);
    }

    modifier whenAuctionIsFinished() {
        _;
    }

    function testFuzz_ShouldFail_CallerIsBeneficiary(
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

        // Set alice as the beneficiary
        bytes32 auctionHash = keccak256(abi.encode(details));
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_BENEFICIARY));
        vm.store(address(auction), slot, bytes32(uint256(uint160(users.alice)))); // value should be alice's address

        // Try to withdraw
        vm.expectRevert(Errors.BeneficiaryCannotWithdraw.selector);
        auction.withdraw(auctionData);
    }

    modifier whenCallerNotBeneficiary() {
        _;
    }

    function testFuzz_ShouldFail_ZeroWithdrawAmount(
        Params memory params,
        uint256 time
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerNotBeneficiary
    {
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
        auction.withdraw(auctionData);
    }

    modifier givenWhenWithdrawAmountNonZero() {
        _;
    }

    function testFuzz_Withdraw(
        Params memory params,
        uint256 time,
        uint256 bid
    )
        external
        givenWhenAuctionMade
        whenAuctionIsFinished
        whenCallerNotBeneficiary
        givenWhenWithdrawAmountNonZero
    {
        Auction.Details memory details = fuzzAuctionDetails(params);
        bytes memory auctionData = abi.encode(details);

        // Create the auction
        createAuction(details);

        // Warp to a time when the auction is on
        vm.warp(details.startTime + 1);

        // Setting up highest bids
        resetPrank(users.bob);
        auction.bid(auctionData, FheHelper.encrypt128(BID1));

        resetPrank(users.charlee);
        auction.bid(auctionData, FheHelper.encrypt128(BID2));

        // Setting up alice's losing bid
        bid = bound(bid, 1, BID2);
        resetPrank(users.alice);
        auction.bid(auctionData, FheHelper.encrypt128(bid));

        // Warp to a time after the auction ends
        uint256 endTime = details.startTime + details.duration;
        vm.assume(time > endTime);
        vm.warp(time);

        // Cached state before alice withdraws
        uint256 alice_originalBalance = decryptedTokenBalance(users.alice);
        uint256 auction_originalBalance = decryptedTokenBalance(address(auction));

        // Alice calls withdraw
        auction.withdraw(auctionData);

        // Assert that the encrypted token balance of alice increases by her losing bid & the contract balance decreases
        assertEq(decryptedTokenBalance(users.alice), alice_originalBalance + bid, "balanceOfEncrypted");
        assertEq(decryptedTokenBalance(address(auction)), auction_originalBalance - bid, "balanceOfEncrypted");

        // Assert that the `bidsPerAddr` value for alice is reduced to zero
        assertEq(getBidPerAddr(keccak256(auctionData), users.alice), 0, "bidsPerAddr");
    }
}

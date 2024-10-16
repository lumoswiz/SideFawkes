// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Auction } from "src/types/DataTypes.sol";
import { VickreyAuction } from "src/VickreyAuction.sol";
import { Vault } from "src/Vault.sol";
import { EncryptedVault } from "src/EncryptedVault.sol";
import { Payment } from "src/token/Payment.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { FHE, inEuint128, euint128 } from "@fhenixprotocol/contracts/FHE.sol";

import { StdUtils } from "forge-std/src/StdUtils.sol";
import { Asset } from "test/mocks/Asset.sol";
import { Calculations } from "test/utils/Calculations.sol";
import { Constants } from "test/utils/Constants.sol";
import { Defaults } from "test/utils/Defaults.sol";
import { Events } from "test/utils/Events.sol";
import { FheHelper } from "test/utils/FheHelper.sol";
import { Users } from "test/utils/Types.sol";
import { Utils } from "test/utils/Utils.sol"; // inheritcs 'Test'

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Calculations, Constants, Events, Utils {
    /*----------------------------------------------------------*|
    |*  # VARIABLES                                             *|
    |*----------------------------------------------------------*/

    Users internal users;
    Defaults internal defaults;

    /*----------------------------------------------------------*|
    |*  # TEST CONTRACTS                                        *|
    |*----------------------------------------------------------*/

    Asset internal asset;
    Payment internal payment;
    VickreyAuction internal auction;

    /*----------------------------------------------------------*|
    |*  # SETUP FUNCTION                                        *|
    |*----------------------------------------------------------*/
    function setUp() public virtual {
        // Required to mock FHE Operations
        initializeFhe();

        // Deploy the base test contracts
        asset = new Asset{ salt: SALT }();
        address assetAddress_ = vm.computeCreate2Address(SALT, keccak256(type(Asset).creationCode), address(this));
        assertEq(assetAddress_, address(asset));

        payment = new Payment();

        // Deploy the auction contract
        auction = new VickreyAuction(address(payment), MAX_DURATION);

        // Deploy the defaults contract
        defaults = new Defaults();
        defaults.setAsset(asset);
        defaults.setPayment(payment);

        // Create the users
        users.proposer = createProposer();
        users.alice = createUser("alice");
        users.bob = createUser("bob");
        users.charlee = createUser("charlee");
        users.beneficiary = createUser("beneficiary");

        // Set users
        defaults.setUsers(users);

        // Warp to May 1, 2024 at 00:00 GMT
        vm.warp(MAY_1_2024);
    }

    /*----------------------------------------------------------*|
    |*  # HELPERS                                               *|
    |*----------------------------------------------------------*/

    function createProposer() internal returns (address) {
        // Create proposer address
        address proposer_ = vm.addr(generatePk("proposer"));
        vm.label(proposer_, "proposer");

        // Mint NFT asset for proposer
        asset.mint(proposer_, defaults.TOKEN_ID());

        // Approve auction contract
        uint256 tokenId = defaults.TOKEN_ID();
        vm.prank(proposer_);
        asset.approve(address(auction), tokenId);

        return proposer_;
    }

    function createUser(string memory name) internal returns (address) {
        // Create user address from a private-key
        address user = vm.addr(generatePk(name));
        vm.label(user, name);

        // Mint encrypted/shielded amount to user and approve auction contract as spender
        inEuint128 memory amount = FheHelper.encrypt128(defaults.INITIAL_BALANCE());
        payment.mintEncrypted(user, amount);
        vm.prank(user);
        payment.approveEncrypted(address(auction), amount);

        return user;
    }

    function mintEncryptedAmount(address user, uint256 amount) internal {
        payment.mintEncrypted(user, FheHelper.encrypt128(amount));
    }

    function mintAndApproveEncryptedAmount(address user, uint256 amount) internal {
        inEuint128 memory ea = FheHelper.encrypt128(amount);
        payment.mintEncrypted(user, ea);
        vm.prank(user);
        payment.approveEncrypted(user, ea);
    }

    function decryptedTokenBalance(address user) internal view returns (uint256) {
        return FHE.decrypt(payment.balanceOfEncrypted(user));
    }

    function createAuction(Auction.Details memory details) internal {
        // Reset the prank
        resetPrank(users.proposer);

        // Create the auction
        auction.createAuction(details);
    }

    // Accessing storage variables

    function getAuctionsMade(bytes32 auctionHash) internal view returns (bool) {
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_AUCTIONS_MADE));
        return uint256(vm.load(address(auction), slot)) == 1 ? true : false;
    }

    function getHighestBids(bytes32 auctionHash) internal view returns (uint256, uint256) {
        bytes32 slot0 = keccak256(abi.encode(auctionHash, SLOT_BIDS));
        bytes32 slot0Value = vm.load(address(auction), slot0);

        bytes32 slot1 = bytes32(uint256(slot0) + uint256(1));
        bytes32 slot1Value = vm.load(address(auction), slot1);

        return (uint256(slot0Value), uint256(slot1Value));
    }

    function getBidPerAddr(bytes32 auctionHash, address bidder) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encode(bidder, keccak256(abi.encode(auctionHash, SLOT_BIDS_PER_ADDR))));
        return uint256(vm.load(address(auction), slot));
    }

    function getBeneficiary(bytes32 auctionHash) internal view returns (address) {
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_BENEFICIARY));
        return address(uint160(uint256(vm.load(address(auction), slot))));
    }

    function getClaimed(bytes32 auctionHash) internal view returns (bool) {
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_CLAIMED));
        return uint256(vm.load(address(auction), slot)) == 1 ? true : false;
    }

    function getWithdrawn(bytes32 auctionHash) internal view returns (bool) {
        bytes32 slot = keccak256(abi.encode(auctionHash, SLOT_WITHDRAWN));
        return uint256(vm.load(address(auction), slot)) == 1 ? true : false;
    }
}

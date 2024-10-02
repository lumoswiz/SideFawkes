// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { inEuint128, euint128, ebool, FHE } from "@fhenixprotocol/contracts/FHE.sol";
import { IFHERC20 } from "@fhenixprotocol/contracts/experimental/token/FHERC20/IFHERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Vault } from "src/Vault.sol";
import { EncryptedVault } from "src/EncryptedVault.sol";
import { Auction } from "src/types/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";

contract VickreyAuction is Vault, EncryptedVault {
    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANT DEFINITIONS                      *|
    |*----------------------------------------------------------*/

    uint256 public immutable MAXIMUM_DURATION;

    address public immutable PAYMENT_TOKEN;

    /**
     * Mapping whether an auction has been made.
     */
    mapping(bytes32 auctionHash => bool isMade) public auctionsMade;

    /**
     * Mapping the highest bids of an auction.
     */
    mapping(bytes32 auctionHash => Auction.Bids highestBids) internal bids;

    /**
     * Mapping the encrypted bids for bidders in an auction.
     */
    mapping(bytes32 auctionHash => mapping(address bidder => euint128 encryptedBid)) internal bidsPerAddr;

    /**
     * Mapping the highest bidder for an auction.
     */
    mapping(bytes32 auctionHash => address highestBidder) internal beneficiary;

    /**
     * Mapping whether the beneficiary has claimed the ERC-721 asset.
     */
    mapping(bytes32 auctionHash => bool isClaimed) internal claimed;

    /**
     * Mapping whether the auction proposer has withdrawn the shielded ERC-20 tokens.
     */
    mapping(bytes32 auctionHash => bool isWithdrawn) internal withdrawn;

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address _paymentToken, uint256 _maxDuration) {
        PAYMENT_TOKEN = _paymentToken;
        MAXIMUM_DURATION = _maxDuration;
    }

    /*----------------------------------------------------------*|
    |*  # AUCTION FUNCTIONS                                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice A caller can create an auction for their ERC-721 asset.
     * @dev Assumes prior token approvals.
     * @param auction Auction struct.
     */
    function createAuction(Auction.Details memory auction) external {
        bytes32 auctionHash = keccak256(abi.encode(auction));

        // Check auction hash has been made
        if (auctionsMade[auctionHash]) revert Errors.AuctionHashAlreadyMade(auctionHash);

        // Check caller is the proposer
        if (msg.sender != auction.proposer) revert Errors.CallerIsNotStatedProposer({ proposer: auction.proposer });

        // Check start time validity
        if (auction.startTime < block.timestamp) revert Errors.InvalidAuctionStartTime({ time: auction.startTime });

        // Check duration validity
        if (auction.duration > MAXIMUM_DURATION) {
            revert Errors.InvalidAuctionDuration({ duration: auction.duration });
        }

        // Transfer ERC-721 to the vault
        _pullAsset(auction.assetAddress, auction.tokenId, auction.proposer);

        // Auction is made
        auctionsMade[auctionHash] = true;
    }

    /**
     * @notice A caller can create a bid in an auction.
     * @dev Assumes prior token approvals.
     * @dev Value is the bid price. If another bid is made, this is not the incremental amaount the bidder wants to add.
     * @param auctionData Encoded auction data.
     * @param value Encoded bid value, denominated in shielded ERC-20 token amount.
     */
    function bid(bytes memory auctionData, inEuint128 memory value) external {
        // Decode auction data
        Auction.Details memory auction = decodeAuctionData(auctionData);

        // Auction hash
        bytes32 auctionHash = keccak256(abi.encode(auction));

        // Check auction is made
        if (!auctionsMade[auctionHash]) revert Errors.AuctionNotMade({ auctionHash: auctionHash });

        // Check auction is on
        if (block.timestamp < auction.startTime || block.timestamp > auction.startTime + auction.duration) {
            revert Errors.AuctionNotOn();
        }

        // Load state variables
        address currentBeneficiary = beneficiary[auctionHash];
        euint128 previousBid = bidsPerAddr[auctionHash][msg.sender];

        // New bid as euint128
        euint128 newBid = FHE.asEuint128(value);

        // Require: new bid is greater than the previous bid
        FHE.req(newBid.gt(previousBid));

        // Calcualte the bid diff - this is the shielded ERC-20 transfer amount.
        // Maximum amount should be equal to the `newBid`.
        euint128 bidDiff = newBid.sub(previousBid);

        // Transfer shielded tokens from caller to the vault.
        _pullTokens(PAYMENT_TOKEN, bidDiff, msg.sender);

        // Update bid for the calling address
        bidsPerAddr[auctionHash][msg.sender] = newBid;

        // Compare to highest bids
        Auction.Bids storage bids_ = bids[auctionHash];

        // Bid & benficiary state variables
        ebool bid1Bool = newBid.gt(bids_.bid1);
        address beneficiary_ = FHE.decrypt(bid1Bool) == true ? msg.sender : currentBeneficiary;

        euint128 bid1Return = FHE.select(bid1Bool, newBid, bids_.bid1);
        euint128 bid2Return =
            FHE.select(newBid.gt(bids_.bid2), FHE.select(newBid.gt(bids_.bid1), bids_.bid2, newBid), bids_.bid2);

        bids_.bid1 = bid1Return;
        bids_.bid2 = bid2Return;

        if (beneficiary_ != currentBeneficiary) {
            beneficiary[auctionHash] = beneficiary_;
        }
    }

    /**
     * @notice A losing bidder in an auction that has closed can claim their shielded ERC-20 tokens.
     * @dev The caller is expected to be a bidder (other than the highest bidder).
     * @param auctionData Encoded auction data.
     */
    function withdraw(bytes memory auctionData) external {
        // Decode auction data
        Auction.Details memory auction = decodeAuctionData(auctionData);

        // Auction hash
        bytes32 auctionHash = keccak256(abi.encode(auction));

        // Check auction is made
        if (!auctionsMade[auctionHash]) revert Errors.AuctionNotMade({ auctionHash: auctionHash });

        // Check the auction is over
        if (block.timestamp < auction.startTime + auction.duration) revert Errors.AuctionIsOn();

        // Check that the caller is not the beneficiary
        if (msg.sender == beneficiary[auctionHash]) revert Errors.BeneficiaryCannotWithdraw();

        // Cache withdraw amount
        euint128 withdrawAmount = bidsPerAddr[auctionHash][msg.sender];

        // Require: withdraw amount is not equal to zero
        FHE.req(withdrawAmount.ne(FHE.asEuint128(0)));

        // Update callers shield ERC-20 bid balance
        bidsPerAddr[auctionHash][msg.sender] = FHE.asEuint128(0);

        // Transfer shielded tokens to the caller from the vault
        _pushTokens(PAYMENT_TOKEN, withdrawAmount, msg.sender);
    }

    /*----------------------------------------------------------*|
    |*  # CLAIM/WITHDRAW FUNCTIONS OF SUCCESSFUL AUCTION        *|
    |*----------------------------------------------------------*/

    /**
     * @notice The beneficiary can claim their ERC-721 asset in a closed auction that succeeded.
     * @dev Auction is successful when second highest bid cleared the reserve price.
     * @dev The caller is expected to be the highest bidder in an auction.
     * @dev Highest bidder pays the second highest price, so transfers diff of shielded ERC-20 tokens back to them.
     * @param auctionData Encoded auction data.
     */
    function claimSuccess(bytes memory auctionData) external {
        // Decode auction data
        Auction.Details memory auction = decodeAuctionData(auctionData);

        // Auction hash
        bytes32 auctionHash = keccak256(abi.encode(auction));

        // Check the asset has not been claimed successfully
        if (claimed[auctionHash]) revert Errors.AlreadyClaimed();

        // Check the auction is over
        if (block.timestamp < auction.startTime + auction.duration) revert Errors.AuctionIsOn();

        // Check the caller is the beneficiary
        if (msg.sender != beneficiary[auctionHash]) revert Errors.CallerNotBeneficiary();

        // Check that the auction was successful: second highest bid is greater than the reserve price
        Auction.Bids memory b = bids[auctionHash];

        // Require: second highest bid is greater than or equal to the reserve auction price
        FHE.req(b.bid2.gte(FHE.asEuint128(auction.reservePrice)));

        // Update claimed
        claimed[auctionHash] = true;

        // Beneficiary pays second highest bid, transfer diff shielded ERC-20 tokens
        euint128 bidDiff = b.bid1.sub(b.bid2);

        // Transfer shielded tokens to the caller from the vault
        _pushTokens(PAYMENT_TOKEN, bidDiff, msg.sender);

        // Transfer asset to the beneficiary
        _pushAsset(auction.assetAddress, auction.tokenId, msg.sender);
    }

    /**
     * @notice An auction's proposer can withdraw their shielded ERC-20 tokens from a successful auction.
     * @dev A successful auction means the second highest bid is greater than, or equal to, the reserve price.
     * @param auctionData Encoded auction data.
     */
    function withdrawSuccess(bytes memory auctionData) external {
        // Decode auction data
        Auction.Details memory auction = decodeAuctionData(auctionData);

        // Auction hash
        bytes32 auctionHash = keccak256(abi.encode(auction));

        // Check the asset has not been withdrawn successfully
        if (withdrawn[auctionHash]) revert Errors.AlreadyWithdrawn();

        // Check the auction is over
        if (block.timestamp < auction.startTime + auction.duration) revert Errors.AuctionIsOn();

        // Check the caller is the auction proposer
        if (msg.sender != auction.proposer) revert Errors.CallerNotBeneficiary();

        // Check that the auction was successful: second highest bid is greater than the reserve price
        // Cache the bids
        Auction.Bids memory b = bids[auctionHash];

        // Require: second highest bid is greater than, or equal to, the auction reserve price
        FHE.req(b.bid2.gte(FHE.asEuint128(auction.reservePrice)));

        // Update withdrawn
        withdrawn[auctionHash] = true;

        // Transfer shield ERC-20 tokens to the proposer
        euint128 bid2 = bids[auctionHash].bid2;

        // Transfer shielded tokens to the caller from the vault
        _pushTokens(PAYMENT_TOKEN, bid2, msg.sender);
    }

    /*----------------------------------------------------------*|
    |*  # CLAIM/WITHDRAW FUNCTIONS OF UNSUCCESSFUL AUCTION      *|
    |*----------------------------------------------------------*/

    /**
     * @notice The beneficiary can claim their shielded ERC-20 tokens from a closed auction that was unsuccessful.
     * @dev Auction is unsuccessful when second highest bid fails to clear the reserve price.
     * @dev The caller is expected to be the highest bidder in an auction.
     * @param auctionData Encoded auction data.
     */
    function claimFailed(bytes memory auctionData) external {
        // Decode auction data
        Auction.Details memory auction = decodeAuctionData(auctionData);

        // Auction hash
        bytes32 auctionHash = keccak256(abi.encode(auction));

        // Check the asset has not been claimed successfully
        if (claimed[auctionHash]) revert Errors.AlreadyClaimed();

        // Check the auction is over
        if (block.timestamp < auction.startTime + auction.duration) revert Errors.AuctionIsOn();

        // Check the caller is the beneficiary
        if (msg.sender != beneficiary[auctionHash]) revert Errors.CallerNotBeneficiary();

        // Check that the auction was successful: second highest bid is greater than the reserve price
        Auction.Bids memory b = bids[auctionHash];

        // Require: second highest bid is less than the reserve auction price
        FHE.req(b.bid2.lt(FHE.asEuint128(auction.reservePrice)));

        // Update claimed
        claimed[auctionHash] = true;

        // Transfer shielded tokens to the caller from the vault
        _pushTokens(PAYMENT_TOKEN, b.bid1, msg.sender);
    }

    /**
     * @notice An auction's proposer can withdraw their ERC-721 asset from a closed auction that was unsuccessful.
     * @dev Auction is unsuccessful when second highest bid fails to clear the reserve price.
     * @param auctionData Encoded auction data.
     */
    function withdrawFailed(bytes memory auctionData) external {
        // Decode auction data
        Auction.Details memory auction = decodeAuctionData(auctionData);

        // Auction hash
        bytes32 auctionHash = keccak256(abi.encode(auction));

        // Check the asset has not been withdrawn successfully
        if (withdrawn[auctionHash]) revert Errors.AlreadyWithdrawn();

        // Check the auction is over
        if (block.timestamp < auction.startTime + auction.duration) revert Errors.AuctionIsOn();

        // Check the caller is the auction proposer
        if (msg.sender != auction.proposer) revert Errors.CallerNotBeneficiary();

        // Cache the bids
        Auction.Bids memory b = bids[auctionHash];

        // Require: second highest bid is less than the auction reserve price
        FHE.req(b.bid2.lt(FHE.asEuint128(auction.reservePrice)));

        // Update withdrawn
        withdrawn[auctionHash] = true;

        // Transfer asset back to the proposer
        _pushAsset(msg.sender, auction.tokenId, msg.sender);
    }

    /*----------------------------------------------------------*|
    |*  # ENCODING FUNCTIONS                                    *|
    |*----------------------------------------------------------*/

    function decodeAuctionData(bytes memory auctionData) public pure returns (Auction.Details memory) {
        return abi.decode(auctionData, (Auction.Details));
    }
}

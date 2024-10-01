// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IFHERC20 } from "src/token/IFHERC20.sol";
import { Auction } from "src/types/DataTypes.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Payment } from "test/mocks/Payment.sol";

import { FHE, euint128 } from "@fhenixprotocol/contracts/FHE.sol";
import { Constants } from "test/utils/Constants.sol";
import { Users } from "test/utils/Types.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract Defaults is Constants {
    Payment private payment;
    IERC721 private asset;
    Users private users;

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() { }

    /*----------------------------------------------------------*|
    |*  # HELPERS                                               *|
    |*----------------------------------------------------------*/

    function setPayment(Payment payment_) public {
        payment = payment_;
    }

    function setAsset(IERC721 asset_) public {
        asset = asset_;
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }

    function assetOwner() public view returns (address) {
        return asset.ownerOf(TOKEN_ID);
    }

    /*----------------------------------------------------------*|
    |*  # STRUCTS                                               *|
    |*----------------------------------------------------------*/

    function details() public view returns (Auction.Details memory) {
        return Auction.Details({
            startTime: START_TIME,
            proposer: users.proposer,
            duration: DURATION,
            assetAddress: address(asset),
            tokenId: TOKEN_ID,
            reservePrice: FheHelper.encrypt128(RESERVE_PRICE)
        });
    }

    /*----------------------------------------------------------*|
    |*  # PARAMS                                                *|
    |*----------------------------------------------------------*/

    function auctionData() public view returns (bytes memory) {
        return abi.encode(details());
    }
}

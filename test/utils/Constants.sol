// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

abstract contract Constants {
    // GENERIC
    uint128 internal constant MAX_UINT128 = type(uint128).max;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint40 internal constant MAX_UINT40 = type(uint40).max;
    uint40 public constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1
    uint40 internal constant MAY_1_2024 = 1_714_518_000;

    // AUCTION
    uint256 public constant BID1 = 80e18;
    uint256 public constant BID2 = 75e18;
    uint256 public constant INITIAL_BALANCE = 100e18;

    uint40 public constant START_TIME = MAY_1_2024 + 2 days;
    uint40 public constant DURATION = 7 days;
    uint256 public constant TOKEN_ID = 9;
    uint256 public constant RESERVE_PRICE = 60e18;
    uint40 public constant MAX_DURATION = 30 days;

    // ASSET
    bytes32 internal constant SALT = keccak256("ASSET_SALT");
    address public constant ASSET = 0xa9A96E15dE97C9f0b9560eF38e077e101Acf01B8;

    // PRIVATE KEYS
    uint256 internal constant PROPOSER_PK = 0x2707a3e4824ab2b21959c6c7d69ee8c2bc1cf46d4c7a98682fe74a1f9ad1d7e6;
    uint256 internal constant ALICE_PK = 0xd968093e3f26aef74ce7b94c901ee2c858917c6ff3dd81f7b4710078123489f3;
    uint256 internal constant BOB_PK = 0x84ee0a95a694cb8c0d7a9e548b55bab5815a6d9aa33fd7a67e74d48a2726670c;
    uint256 internal constant BENEFICIARY_PK = 0x416da30dae7e30b018bd80443676ca747361026206b2765965d197e9ed4c84b2;

    // VICKREY AUCTION SLOTS
    uint256 internal constant SLOT_AUCTIONS_MADE = 0;
    uint256 internal constant SLOT_BIDS = 1;
    uint256 internal constant SLOT_BIDS_PER_ADDR = 2;
    uint256 internal constant SLOT_BENEFICIARY = 3;
    uint256 internal constant SLOT_CLAIMED = 4;
    uint256 internal constant SLOT_WITHDRAWN = 5;
}

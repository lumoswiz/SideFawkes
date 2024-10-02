// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

struct Users {
    // Default auction proposer
    address proposer;
    // Impartial user.
    address alice;
    // Impartial user
    address bob;
    // Impartial user
    address charlee;
    // Default auction beneficiary.
    address beneficiary;
}

/// @dev Params for fuzzing auction details
struct Params {
    uint40 startTime;
    uint40 duration;
    uint256 reservePrice;
}

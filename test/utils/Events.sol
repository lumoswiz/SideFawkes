// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

abstract contract Events {
    /*----------------------------------------------------------*|
    |*  # VAULT                                                 *|
    |*----------------------------------------------------------*/

    event VaultPull(address indexed asset, uint256 indexed id, address indexed origin);

    event VaultPush(address indexed asset, uint256 indexed id, address indexed beneficiary);
}

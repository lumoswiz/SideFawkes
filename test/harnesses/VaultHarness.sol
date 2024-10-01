// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Vault } from "src/Vault.sol";

contract VaultHarness is Vault {
    function exposed__pullAsset(address asset, uint256 id, address origin) external {
        _pullAsset(asset, id, origin);
    }

    function exposed__pushAsset(address asset, uint256 id, address beneficiary) external {
        _pushAsset(asset, id, beneficiary);
    }

    function exposed__checkTransfer(
        address asset,
        uint256 id,
        uint256 originalBalance,
        address checkedAddress
    )
        external
        view
    {
        _checkTransfer(asset, id, originalBalance, checkedAddress);
    }
}

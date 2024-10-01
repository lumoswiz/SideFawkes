// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { EncryptedVault } from "src/EncryptedVault.sol";
import { euint128 } from "@fhenixprotocol/contracts/FHE.sol";

contract EncryptedVaultHarness is EncryptedVault {
    function exposed__pullTokens(address asset, euint128 amount, address origin) external {
        _pullTokens(asset, amount, origin);
    }

    function exposed__pushTokens(address asset, euint128 amount, address beneficiary) external {
        _pushTokens(asset, amount, beneficiary);
    }

    function exposed__checkTransfer(
        address asset,
        euint128 amount,
        euint128 originalBalance,
        address checkedAddress
    )
        external
        view
    {
        _checkTransfer(asset, amount, originalBalance, checkedAddress);
    }
}

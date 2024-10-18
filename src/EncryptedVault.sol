// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { FHE, euint128 } from "@fhenixprotocol/contracts/FHE.sol";
import { Payment } from "src/token/Payment.sol";

/// Forked from: PWN Vault
/// @dev Vault for handling FHERC20 tokens
contract EncryptedVault {
    /*----------------------------------------------------------*|
    |*  # TRANSFER FUNCTIONS                                    *|
    |*----------------------------------------------------------*/

    function _pullTokens(address asset, euint128 amount, address origin) internal {
        euint128 originalBalance = balanceOf(asset, address(this));

        Payment(asset).transferFromEncrypted(origin, address(this), amount);
        _checkTransfer(asset, amount, originalBalance, address(this));
    }

    function _pushTokens(address asset, euint128 amount, address beneficiary) internal {
        euint128 originalBalance = balanceOf(asset, beneficiary);

        Payment(asset).transferEncrypted(beneficiary, amount);
        _checkTransfer(asset, amount, originalBalance, beneficiary);
    }

    function _checkTransfer(
        address asset,
        euint128 amount,
        euint128 originalBalance,
        address checkedAddress
    )
        internal
        view
    {
        euint128 expectedBalance = FHE.add(originalBalance, amount);

        FHE.req(expectedBalance.eq(balanceOf(asset, checkedAddress)));
    }

    /*----------------------------------------------------------*|
    |*  # BALANCE OF                                            *|
    |*----------------------------------------------------------*/

    function balanceOf(address asset, address target) public view returns (euint128) {
        return Payment(asset).balanceOfEncrypted(target);
    }
}

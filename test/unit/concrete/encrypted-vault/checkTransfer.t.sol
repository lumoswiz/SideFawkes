// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EncryptedVault_Unit_Concrete_Test } from "test/unit/concrete/encrypted-vault/EncryptedVault.t.sol";
import { FHE, euint128, ebool } from "@fhenixprotocol/contracts/FHE.sol";

contract CheckTransfer_Unit_Concrete_Test is EncryptedVault_Unit_Concrete_Test {
    function test_ShouldRevert_AmountTokensNotTransferred() external {
        // Mint an encrypted amount of tokens
        address user = makeAddr("user");
        mintEncryptedAmount(user, defaults.INITIAL_BALANCE());

        // Caching values for vm.expectRevert()
        euint128 amount = encrypt(1);
        euint128 originalBalance = encrypt(defaults.INITIAL_BALANCE());

        // Call `_checkTransfer`
        vm.expectRevert("MockFheOps: req");
        harness.exposed__checkTransfer(address(payment), amount, originalBalance, user);
    }
}

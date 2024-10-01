// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EncryptedVault_Unit_Concrete_Test } from "test/unit/concrete/encrypted-vault/EncryptedVault.t.sol";
import { FHE, euint128 } from "@fhenixprotocol/contracts/FHE.sol";

contract PushTokens_Unit_Concrete_Test is EncryptedVault_Unit_Concrete_Test {
    function setUp() public override {
        super.setUp();

        // Mint encrypted tokens for the harness contract
        mintEncryptedAmount(address(harness), defaults.INITIAL_BALANCE());
    }

    function test_HarnessDoesNotHaveEnoughTokens_NoTransfer() external {
        // Call `_pushTokens` with an encrypted amount greater than the vault's balance should revert
        euint128 amount = FHE.asEuint128(defaults.INITIAL_BALANCE() + 1);
        vm.expectRevert("MockFheOps: req");
        harness.exposed__pushTokens(address(payment), amount, users.alice);
    }

    function test_pushTokens() external {
        // Call `_pushTokens`
        harness.exposed__pushTokens(address(payment), FHE.asEuint128(defaults.INITIAL_BALANCE()), users.alice);

        // Unseal the balance
        uint256 alice_balance = decryptedTokenBalance(users.alice);

        // Assert: alice's balance increased by INITIAL_TOKEN_BALANCE
        assertEq(alice_balance, 2 * defaults.INITIAL_BALANCE());
    }
}

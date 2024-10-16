// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EncryptedVault_Unit_Concrete_Test } from "test/unit/concrete/encrypted-vault/EncryptedVault.t.sol";
import { FHE, euint128, inEuint128 } from "@fhenixprotocol/contracts/FHE.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract PushTokens_Unit_Concrete_Test is EncryptedVault_Unit_Concrete_Test {
    function setUp() public override {
        super.setUp();

        // Mint encrypted tokens for the harness contract
        mintEncryptedAmount(address(harness), defaults.INITIAL_BALANCE());
    }

    function test_VaultDoesNotHaveEnoughTokens_NoTransfer() external {
        // Call `_pushTokens` with an encrypted amount greater than the vault's balance should revert
        euint128 amount = FHE.asEuint128(defaults.INITIAL_BALANCE() + 1);
        vm.expectRevert();
        harness.exposed__pushTokens(address(payment), amount, users.alice);
    }

    function test_PushTokens() external {
        // Call `_pushTokens`
        euint128 amount = FHE.asEuint128(defaults.INITIAL_BALANCE());
        harness.exposed__pushTokens(address(payment), amount, users.alice);

        // Unseal the balance
        uint256 alice_balance = decryptedTokenBalance(users.alice);

        // Assert: alice's balance increased by INITIAL_TOKEN_BALANCE
        assertEq(alice_balance, 2 * defaults.INITIAL_BALANCE());
    }
}

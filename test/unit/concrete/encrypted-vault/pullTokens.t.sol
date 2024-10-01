// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EncryptedVault_Unit_Concrete_Test } from "test/unit/concrete/encrypted-vault/EncryptedVault.t.sol";
import { FHE, euint128, inEuint128 } from "@fhenixprotocol/contracts/FHE.sol";
import { FheHelper } from "test/utils/FheHelper.sol";

contract PullTokens_Unit_Concrete_Test is EncryptedVault_Unit_Concrete_Test {
    function test_NoEncryptedTokenApproval_InitialBalanceShouldBeUnchanged() external {
        // Mint an encrypted amount of tokens
        uint256 pk = generatePk("user");
        address user = vm.addr(pk);
        mintEncryptedAmount(user, INITIAL_BALANCE);

        // Call `_pullTokens` should revert
        euint128 amount = FHE.asEuint128(defaults.INITIAL_BALANCE());
        vm.expectRevert("MockFheOps: req");
        harness.exposed__pullTokens(address(payment), amount, user);
    }

    modifier encryptedTokenApproval() {
        _;
    }

    function test_pullTokens() external encryptedTokenApproval {
        inEuint128 memory inAmount = FheHelper.encrypt128(INITIAL_BALANCE);

        // Approve the harness contract
        vm.prank(users.alice);
        payment.approveEncrypted(address(harness), inAmount);

        // Call `_pullTokens`
        harness.exposed__pullTokens(address(payment), FHE.asEuint128(INITIAL_BALANCE), users.alice);

        // Unseal the balance
        uint256 alice_balance = decryptedTokenBalance(users.alice);

        // Assert the encrypted tokens have been transferred
        assertEq(alice_balance, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Vault_Unit_Concrete_Test } from "test/unit/concrete/vault/Vault.t.sol";
import { Vault } from "src/Vault.sol";

contract CheckTransfer_Unit_Concrete_Test is Vault_Unit_Concrete_Test {
    function test_ShouldFail_IncompleteTransfer_CheckedAddressNotOwner() external {
        uint256 originalBalance_ = 0;

        vm.expectRevert(Vault.IncompleteTransfer.selector);
        harness.exposed__checkTransfer(address(asset), TOKEN_ID, originalBalance_, users.alice);
    }

    function test_ShouldFail_IncompleteTransfer_OriginalBalanceIsOne() external {
        uint256 originalBalance_ = 1;

        vm.expectRevert(Vault.IncompleteTransfer.selector);
        harness.exposed__checkTransfer(address(asset), TOKEN_ID, originalBalance_, users.proposer);
    }

    function test_CheckTransfer() external view {
        uint256 originalBalance_ = 0;
        harness.exposed__checkTransfer(address(asset), TOKEN_ID, originalBalance_, users.proposer);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { VaultHarness } from "test/harnesses/VaultHarness.sol";
import { Base_Test } from "test/Base.t.sol";

contract Vault_Unit_Concrete_Test is Base_Test {
    VaultHarness internal harness;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the harness
        harness = new VaultHarness();

        // Approve the harness contract
        vm.prank(users.proposer);
        asset.approve(address(harness), TOKEN_ID);
    }
}

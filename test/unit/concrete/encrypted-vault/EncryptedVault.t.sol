// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EncryptedVaultHarness } from "test/harnesses/EncryptedVaultHarness.sol";
import { Base_Test } from "test/Base.t.sol";
import { FHE, euint128 } from "@fhenixprotocol/contracts/FHE.sol";
import { IFHERC20 } from "src/token/IFHERC20.sol";

contract EncryptedVault_Unit_Concrete_Test is Base_Test {
    EncryptedVaultHarness internal harness;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the harness
        harness = new EncryptedVaultHarness();
    }
}

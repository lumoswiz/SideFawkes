// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Vault_Unit_Concrete_Test } from "test/unit/concrete/vault/Vault.t.sol";
import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PullAsset_Unit_Concrete_Test is Vault_Unit_Concrete_Test {
    function test_ShouldFail_ProposerDoesNotOwnTokenId() external {
        uint256 id = 0;
        asset.mint(users.alice, id);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, address(harness), id));
        harness.exposed__pullAsset(address(asset), id, users.proposer);
    }

    function test_PullAsset() external {
        vm.expectEmit();
        emit VaultPull(address(asset), TOKEN_ID, users.proposer);

        harness.exposed__pullAsset(address(asset), TOKEN_ID, users.proposer);

        assertEq(address(harness), defaults.assetOwner(), "pullAsset");
    }
}

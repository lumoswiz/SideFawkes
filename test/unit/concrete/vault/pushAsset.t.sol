// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Vault_Unit_Concrete_Test } from "test/unit/concrete/vault/Vault.t.sol";
import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PushAsset_Unit_Concrete_Test is Vault_Unit_Concrete_Test {
    function test_ShouldFail_VaultDoesNotHaveAsset() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721IncorrectOwner.selector, address(harness), TOKEN_ID, users.proposer
            )
        );
        harness.exposed__pushAsset(address(asset), TOKEN_ID, users.beneficiary);
    }

    function test_PushAsset() external {
        uint256 id = 0;
        asset.mint(address(harness), id);

        vm.expectEmit();
        emit VaultPush(address(asset), id, users.beneficiary);

        harness.exposed__pushAsset(address(asset), id, users.beneficiary);

        assertEq(users.beneficiary, asset.ownerOf(id), "pushAsset");
    }
}

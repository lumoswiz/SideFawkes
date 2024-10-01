// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { FHERC20 } from "src/token/FHERC20.sol";

import { inEuint128 } from "@fhenixprotocol/contracts/FHE.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

error FHERC20NotAuthorized();

contract Payment is FHERC20("SHIELD", "SHIELD"), AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mintEncrypted(address recipient, inEuint128 memory amount) public {
        if (hasRole(MINTER_ROLE, msg.sender)) {
            _mintEncrypted(recipient, amount);
        } else {
            revert FHERC20NotAuthorized();
        }
    }

    function mint(address _address, uint256 _amount) public {
        _mint(_address, _amount);
    }
}

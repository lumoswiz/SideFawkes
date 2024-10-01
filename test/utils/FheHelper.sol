// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import { inEuint128, inEaddress, inEbool } from "@fhenixprotocol/contracts/FHE.sol";

library FheHelper {
    function encrypt128(uint256 value) public pure returns (inEuint128 memory) {
        return inEuint128(uint256ToBytes(value), 0);
    }

    function encryptAddress(uint256 value) public pure returns (inEaddress memory) {
        return inEaddress(uint256ToBytes(value), 0);
    }

    function encryptBool(uint256 value) public pure returns (inEbool memory) {
        return inEbool(uint256ToBytes(value), 0);
    }

    function uint256ToBytes(uint256 value) private pure returns (bytes memory) {
        bytes memory result = new bytes(32);

        assembly {
            mstore(add(result, 32), value)
        }

        return result;
    }
}

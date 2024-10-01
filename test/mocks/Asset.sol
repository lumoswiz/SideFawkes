// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Asset is ERC721("NFT", "NFT") {
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Script, console2 } from "forge-std/src/Script.sol";
import { VickreyAuction } from "src/VickreyAuction.sol";
import { Auction } from "src/types/DataTypes.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// forge script script/CreateAuction.s.sol:Create --rpc-url fhenix --broadcast --skip-simulation -vv
contract Create is Script {
    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        VickreyAuction auction = VickreyAuction(0x114d1670b17aDF2a859f31870A40214687c2515a);

        Auction.Details memory details;
        details.startTime = uint40(block.timestamp + 3600);
        details.proposer = 0x94C900F9a5d10C1ac5a884F4d436b952De742933;
        details.duration = 2400;
        details.assetAddress = 0x48BA52b6652226E352AB2fA6F0CD37ffF61a776E;
        details.tokenId = 0;

        vm.startBroadcast(pk);
        IERC721(details.assetAddress).approve(address(auction), details.tokenId);
        auction.createAuction(details);
        vm.stopBroadcast();
    }
}

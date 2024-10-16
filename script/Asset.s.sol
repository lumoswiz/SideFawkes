// // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Script } from "forge-std/src/Script.sol";
import { Asset } from "test/mocks/Asset.sol";

// forge script script/Asset.s.sol:Mint --rpc-url fhenix --broadcast --skip-simulation -vvv
contract Mint is Script {
    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        // Mint details
        Asset asset = Asset(0x48BA52b6652226E352AB2fA6F0CD37ffF61a776E);
        address to = 0x94C900F9a5d10C1ac5a884F4d436b952De742933;
        uint256 tokenId = 0;

        vm.startBroadcast(pk);
        asset.mint(to, tokenId);
        vm.stopBroadcast();
    }
}

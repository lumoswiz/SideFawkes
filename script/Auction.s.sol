// // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Script, console2 } from "forge-std/src/Script.sol";
import { VickreyAuction } from "src/VickreyAuction.sol";
import { Payment } from "src/token/Payment.sol";

// forge script script/Auction.s.sol:Deploy --rpc-url fhenix --broadcast --verify --verifier blockscout --verifier-url
// $VERIFIER_URL --skip-simulation -vvvv

// forge script script/Auction.s.sol:Deploy --rpc-url fhenix --broadcast --skip-simulation -vv
contract Deploy is Script {
    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        Payment payment = Payment(0x7E3C59a33aBdEcc6a5cD29e742a2781494ca7811);

        vm.startBroadcast(pk);
        VickreyAuction auction = new VickreyAuction(address(payment), 3600);
        vm.stopBroadcast();

        console2.log("Vickrey Auction address:", address(auction));
    }
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Script, console2 } from "forge-std/src/Script.sol";
import { Payment } from "src/token/Payment.sol";

// forge script script/Payment.s.sol:Deploy --rpc-url fhenix --broadcast --skip-simulation -vvv
contract Deploy is Script {
    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);
        Payment payment = new Payment();
        vm.stopBroadcast();

        console2.log("Payment address:", address(payment));
    }
}

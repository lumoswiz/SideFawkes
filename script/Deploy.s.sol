// // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { BaseScript } from "./Base.s.sol";

import { VickreyAuction } from "src/VickreyAuction.sol";
import { Asset } from "test/mocks/Asset.sol";
import { Payment } from "test/mocks/Payment.sol";

// forge script script/Deploy.s.sol:Deploy --rpc-url fhenix --broadcast --verify --verifier blockscout --verifier-url
// $VERIFIER_URL --skip-simulation -vvvv
contract Deploy is BaseScript {
    function run() public broadcast {
        Asset asset = new Asset();
        Payment payment = new Payment();
        VickreyAuction auction = new VickreyAuction(address(payment), 10_800);
    }
}

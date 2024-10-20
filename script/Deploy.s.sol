// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ReclaimHide} from "../src/ReclaimHide.sol";

contract DeployScript is Script {
    ReclaimHide public reclaimHide;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // base
        reclaimHide = new ReclaimHide(0x8CDc031d5B7F148ab0435028B16c682c469CEfC3);

        console.log("ReclaimHide deployed at", address(reclaimHide));

        vm.stopBroadcast();
    }
}

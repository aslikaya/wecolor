// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {WeColor} from "../src/WeColor.sol";

contract WeColorScript is Script {
    WeColor public wecolor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        wecolor = new WeColor();

        vm.stopBroadcast();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ContestManager} from "../src/ContestManager.sol";

contract DeployMyCut is Script {
    function run() external returns (ContestManager cmanager) {
        vm.startBroadcast();
        cmanager = new ContestManager();
        vm.stopBroadcast();
        return cmanager;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Pot} from "../src/Pot.sol";
import {ContestManager} from "../src/ContestManager.sol";

import {
    ERC20Mock
} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DeployPot is Script {
    Pot public pot;
    ContestManager public cmanager;
    ERC20Mock public mERC20;

    function run(address user) public returns (Pot, ContestManager, ERC20Mock) {
        // Arrange
        vm.startBroadcast();

        // ERC20 Mock
        mERC20 = new ERC20Mock();

        // Contest Manager
        cmanager = new ContestManager();

        // Mint directly
        mERC20.mint(user, 1e18);
        mERC20.approve(address(cmanager), 1e18);

        address[] memory players = new address[](1);
        players[0] = user;

        uint256 totalRewards = 1e15;

        uint256[] memory reward = new uint256[](1);
        reward[0] = totalRewards;

        address createdContest = cmanager.createContest(
            players,
            reward,
            mERC20,
            totalRewards
        );

        // Deploy
        pot = Pot(createdContest);
        vm.stopBroadcast();

        return (pot, cmanager, mERC20);
    }
}

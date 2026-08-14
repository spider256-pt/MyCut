//SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {Pot} from "../src/Pot.sol";
import {ContestManager} from "../src/ContestManager.sol";

import {
    ERC20Mock
} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DeployPot is Script {
    Pot pot;
    ContestManager cmanager;
    ERC20Mock mERC20;

    function run() public returns (Pot, ContestManager, ERC20Mock) {
        //Arrange
        vm.startBroadcast();
        //ERC20 Mock
        mERC20 = new ERC20Mock();

        //Contest Manager
        cmanager = new ContestManager();

        mERC20.mint(address(this), 1e18);
        mERC20.approve(address(cmanager), 1e18);
        address[] memory players = new address[](1);
        players[0] = address(this);

        uint256 totalRewards = 1e15;

        uint256[] memory reward = new uint256[](1);
        reward[0] = totalRewards;

        address createdContest = cmanager.createContest(
            players,
            reward,
            mERC20,
            totalRewards
        );

        //Deploy
        pot = Pot(createdContest);
        vm.stopBroadcast();
        return (pot, cmanager, mERC20);
    }
}

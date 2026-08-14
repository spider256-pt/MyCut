//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployPot} from "../../script/DeployPotScript.s.sol";
import {Pot} from "../../src/Pot.sol";
import {ContestManager} from "../../src/ContestManager.sol";
import {
    ERC20Mock
} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract TestPot is Test {
    DeployPot deployer;
    Pot pot;
    ContestManager cmanager;
    ERC20Mock merc20;

    address spider = makeAddr("spider");

    address randomAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address constant default_Foundry =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public {
        //Arrange
        deployer = new DeployPot();
        (pot, cmanager, merc20) = deployer.run(default_Foundry);
    }

    function test_BalanceOfTheDefaultFoundry() public {
        //Arrange
        uint256 balanceOfDefault_Foundry = merc20.balanceOf(default_Foundry);
        //Act
        console.log("Balance of user: ", balanceOfDefault_Foundry);
        //Assert
        assertEq(balanceOfDefault_Foundry, 1e18);
    }

    function test_claimCut() public {
        //Arrange
        //Act
        //Assert
    }
}

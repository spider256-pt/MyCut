//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
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

    function setUp() public {
        //Arrange
        deployer = new DeployPot();
        (pot, cmanager, merc20) = deployer.run();
    }
}

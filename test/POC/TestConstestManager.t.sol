//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ContestManager} from "../../src/ContestManager.sol";
import {DeployMyCut} from "../../script/DeployScript.s.sol";

import {
    ERC20Mock
} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract TestContestManager is Test {
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    ContestManager cmanager;
    DeployMyCut deployer;

    ERC20Mock mERC20;

    address spider = makeAddr("spider");

    address constant default_Foundry =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    /*//////////////////////////////////////////////////////////////
                             FUNCTIONAL TEST
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        deployer = new DeployMyCut();
        cmanager = deployer.run();

        mERC20 = new ERC20Mock();
        // mERC20.mint(default_Foundry, 1e20);
    }

    function test_WhoisOwner() public {
        //Arrange
        address owner = cmanager.owner();
        address guessedOwner = default_Foundry;
        //Act
        console.log("Onwer is: ", owner);
        //Assert
        assertEq(owner, guessedOwner);
    }

    function test_createConstest() public {
        //Arrange
        vm.startPrank(default_Foundry);
        address[] memory players = new address[](1);
        players[0] = spider;
        uint256[] memory rewards = new uint256[](1);
        rewards[0] = 1e18;
        uint256 totalrewards = 2e18;
        //Act
        address createdContest = cmanager.createContest(
            players,
            rewards,
            mERC20,
            totalrewards
        );
        vm.stopPrank();
        //Assert
        assertEq(cmanager.contestToTotalRewards(createdContest), totalrewards);
        assertEq(cmanager.contests(0), address(createdContest));
    }

    function test_RevertIfNonOnwerCalls_createContest() public {
        //Arrange
        vm.startPrank(spider);
        address[] memory players = new address[](1);
        players[0] = spider;
        uint256[] memory rewards = new uint256[](1);
        rewards[0] = 1e18;
        uint256 totalRewards = 2e18;
        //Act
        vm.expectRevert();
        address createdContest = cmanager.createContest(
            players,
            rewards,
            mERC20,
            totalRewards
        );
        vm.stopPrank();
    }
}

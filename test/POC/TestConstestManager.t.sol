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

    address public createdContest;

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
        mERC20.mint(default_Foundry, 1e18);
        vm.startPrank(default_Foundry);
        mERC20.approve(address(cmanager), 1e18);
        vm.stopPrank();
        // mERC20.mint(default_Foundry, 1e20);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier createContest() {
        //Arrange
        vm.startPrank(default_Foundry);
        address[] memory players = new address[](1);
        players[0] = spider;
        uint256[] memory rewards = new uint256[](1);
        rewards[0] = 1e18;
        ERC20Mock token = mERC20;
        uint256 totalRewards = 1e15;

        //Act
        createdContest = cmanager.createContest(
            players,
            rewards,
            token,
            totalRewards
        );
        _;
        vm.stopPrank();
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
        //Assert
        assertEq(cmanager.getContests().length, 0, "Should be 0");
    }

    function test_fundContest() public createContest {
        //Arrange
        uint256 index = 0;
        uint256 initialTotalReward = cmanager.getContestTotalRewards(
            address(createdContest)
        );
        uint256 InitialbalanceOfTheUser = mERC20.balanceOf(default_Foundry);

        console.log("initialTotalReward", initialTotalReward);
        console.log("InitialbalanceOfTheUser", InitialbalanceOfTheUser);

        //Act
        // cmanager.fundContest(index);

        // uint256 finalTotalReward = cmanager.getContestTotalRewards(
        //     address(createdContest)
        // );
        //Assert
    }
}

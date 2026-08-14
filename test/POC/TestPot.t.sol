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

    address public modifier_contest;

    address spider = makeAddr("spider");

    address randomAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address constant default_Foundry =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public {
        //Arrange
        deployer = new DeployPot();
        (pot, cmanager, merc20) = deployer.run(default_Foundry);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier createMultipleAddress() {
        // Arrange
        uint256 totalPlayers = 21;
        address[] memory players = new address[](totalPlayers);
        uint256[] memory rewards = new uint256[](totalPlayers);

        // Tot al rewards needed for 20 players getting 1e18 each
        uint256 totalRewards = totalPlayers * 1e18;

        // Start acting as the contest creator
        vm.startPrank(default_Foundry);

        // 1. Give the creator the total funds and approve the manager
        merc20.mint(default_Foundry, totalRewards);
        merc20.approve(address(cmanager), totalRewards);

        // Act
        // 2. Loop starts at 0 to fill every slot in the array
        for (uint256 i = 0; i < totalPlayers; i++) {
            // i + 1 avoids generating address(0)
            address a = address(uint160(i + 1));

            players[i] = a;
            rewards[i] = 1e18;
            players[20] = spider;
            rewards[20] = 1e18;
            // Assign 1e18 reward to this specific player
        }

        ERC20Mock token = merc20;

        // 3. Create the contest
        modifier_contest = cmanager.createContest(
            players,
            rewards,
            token,
            totalRewards
        );

        _; // Execute the test function

        vm.stopPrank();
    }

    function test_OnwerOfTheContestManager() public {
        //Arrange
        address expected_owner = default_Foundry;
        //Act
        address real_owner = cmanager.owner();
        //Assert
        assertEq(
            expected_owner,
            real_owner,
            "Owner should be the default foundry as it deployed the Contest Manager contract"
        );
    }

    function test_BalanceOfTheDefaultFoundry() public {
        //Arrange
        uint256 balanceOfDefault_Foundry = merc20.balanceOf(default_Foundry);
        //Act
        console.log("Balance of user: ", balanceOfDefault_Foundry);
        //Assert
        assertEq(balanceOfDefault_Foundry, 1e18);
    }

    function test_WhoIsTheOwnerOfPot() public {
        //Arrange
        address expected_owner = address(cmanager);
        //Act
        address real_owner = pot.owner();
        //Assert
        assertEq(
            expected_owner,
            real_owner,
            "Owner should be the CManger as it deployed the Pot contract"
        );
    }

    //functionallity

    function test_claimCut() public createMultipleAddress {
        //Arrange
        uint256 totalReward = cmanager.getContestTotalRewards(
            address(modifier_contest)
        );
        uint256 balanceOfPot = merc20.balanceOf(address(modifier_contest));
        cmanager.fundContest(1);
        uint256 balanceOfPotAfterFunding = merc20.balanceOf(
            address(modifier_contest)
        );
        uint256 initial_RemainingReward = cmanager.getContestRemainingRewards(
            address(modifier_contest)
        );

        //Act
        vm.startPrank(spider);
        Pot(modifier_contest).claimCut();
        vm.stopPrank();
        uint256 Final_balanceOfPot = merc20.balanceOf(modifier_contest);
        uint256 Final_RemainingReward = cmanager.getContestRemainingRewards(
            address(modifier_contest)
        );
        //Assert
        assertEq(totalReward, 21 * 1e18);
        assertEq(balanceOfPot, 0);
        assertEq(balanceOfPotAfterFunding, totalReward);
        assertEq(initial_RemainingReward, totalReward);
        assertEq(Final_balanceOfPot, totalReward - 1e18);
        assertEq(Final_RemainingReward, totalReward - 1e18);
    }

    //vulns

    function test_RevertIfLargeNumberofPlayerarePlaying() public {
        // Arrange
        uint256 totalPlayers = 20000;
        address[] memory players = new address[](totalPlayers);
        uint256[] memory rewards = new uint256[](totalPlayers);

        // Tot al rewards needed for 20 players getting 1e18 each
        uint256 totalRewards = totalPlayers * 1e18;

        // Start acting as the contest creator
        vm.startPrank(default_Foundry);

        // 1. Give the creator the total funds and approve the manager
        merc20.mint(default_Foundry, totalRewards);
        merc20.approve(address(cmanager), totalRewards);

        // Act
        // 2. Loop starts at 0 to fill every slot in the array
        for (uint256 i = 0; i < totalPlayers; i++) {
            // i + 1 avoids generating address(0)
            address a = address(uint160(i + 1));

            players[i] = a;
            rewards[i] = 1e18;
            players[19999] = spider;
            rewards[19999] = 1e18;
            // Assign 1e18 reward to this specific player
        }

        ERC20Mock token = merc20;

        // 3. Create the contest
        vm.expectRevert();
        cmanager.createContest(players, rewards, token, totalRewards);
        vm.stopPrank();
    }
}

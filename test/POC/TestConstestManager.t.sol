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

        //For spider
        mERC20.mint(spider, 1e18);
        vm.startPrank(spider);
        mERC20.approve(address(cmanager), 1e18);
        vm.stopPrank();

        //For default Foundry
        mERC20.mint(default_Foundry, 1e18);
        vm.startPrank(default_Foundry);
        mERC20.approve(address(cmanager), 1e18);
        vm.stopPrank();
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
        //Act
        cmanager.fundContest(index);

        uint256 finalTotalReward = cmanager.getContestTotalRewards(
            address(createdContest)
        );
        uint256 finalBalanceOfTheUSer = mERC20.balanceOf(default_Foundry);
        //Assert
        assertEq(
            finalBalanceOfTheUSer,
            InitialbalanceOfTheUser - initialTotalReward,
            "Should be the difference of Balance of the user and the total reward"
        );
    }

    function test_TrackFunds() public createContest {
        //Arrange
        uint256 balanceOfUser = mERC20.balanceOf(default_Foundry);
        uint256 initialTotalReward = cmanager.getContestTotalRewards(
            address(createdContest)
        );
        uint256 IniTialbalanceOfContestPot = mERC20.balanceOf(
            address(createdContest)
        );

        //Assert
        assertEq(IniTialbalanceOfContestPot, 0, "should be 0");
    }

    function test_RevertIfNonOwnerCallsFundContest() public createContest {
        //Arrange

        uint256 InitialBalnceOfSpider = mERC20.balanceOf(spider);
        uint256 InitialTotalReward = cmanager.contestToTotalRewards(
            address(createdContest)
        );
        //Act
        vm.startPrank(spider);
        vm.expectRevert();
        cmanager.fundContest(0);
        vm.stopPrank();
        uint256 finalBalanceOfSPiderAfterTransFer = mERC20.balanceOf(spider);
        //Assert
        assertEq(
            InitialBalnceOfSpider,
            finalBalanceOfSPiderAfterTransFer,
            "Should not be deducted"
        );
    }

    function test_RevertsIfThererNoContestExist(uint256 index) public {
        //Arrange
        index = bound(index, 0, 9);
        vm.startPrank(default_Foundry);
        uint256 InitialBalnceOfdefault = mERC20.balanceOf(default_Foundry);

        //Act
        vm.expectRevert();
        cmanager.fundContest(index);
        uint256 finalBalanceOfdefaultAfterTransFer = mERC20.balanceOf(
            default_Foundry
        );
        vm.stopPrank();
        //Assert
        assertEq(
            cmanager.getContests().length,
            0,
            "Should be 0 as not created"
        );
        assertEq(
            InitialBalnceOfdefault,
            finalBalanceOfdefaultAfterTransFer,
            "Should not be deducted"
        );
    }

    function test_RevertIfTheUserBalanceISLessThanTheTotalReward() public {
        //Arrange
        vm.startPrank(default_Foundry);

        deal(address(mERC20), default_Foundry, 1e14);
        mERC20.approve(address(cmanager), 1e15);

        address[] memory players = new address[](1);
        players[0] = spider;
        uint256[] memory rewards = new uint256[](1);
        rewards[0] = 1e14;
        ERC20Mock token = mERC20;
        uint256 totalRewards = 1e15;

        createdContest = cmanager.createContest(
            players,
            rewards,
            token,
            totalRewards
        );

        uint256 InitialBalanceOfDefautl = mERC20.balanceOf(default_Foundry);
        //Act
        vm.expectRevert(
            ContestManager.ContestManager__InsufficientFunds.selector
        );
        cmanager.fundContest(0);
        uint256 FinalBalanceOfDefault = mERC20.balanceOf(default_Foundry);
        vm.stopPrank();

        //Assert
        assertEq(
            InitialBalanceOfDefautl,
            FinalBalanceOfDefault,
            "Should be same as the user balance is less than the reward"
        );
    }

    function test_closeContest() public createContest {
        //Arrange
        uint256 balanceOfPot = mERC20.balanceOf(address(createdContest));
        uint256 lengthOfTheContestBeforeCancelling = cmanager
            .getContests()
            .length;
        //Act
        cmanager.fundContest(0);

        uint256 AfterFundbalanceOfPot = mERC20.balanceOf(
            address(createdContest)
        );

        uint256 balanceOfUserAfterFunding = mERC20.balanceOf(default_Foundry);

        vm.warp(block.timestamp + 91 days);
        // vm.expectRevert();
        cmanager.closeContest(address(createdContest));
        uint256 lengthOfTheContestAfterCancelling = cmanager
            .getContests()
            .length;

        uint256 balanceOfUSerAfterClosingtheContest = mERC20.balanceOf(
            default_Foundry
        );

        //Assert
        assertEq(
            lengthOfTheContestBeforeCancelling,
            1,
            "Should be 1 as modifier handels the create contest"
        );
        assertEq(
            lengthOfTheContestAfterCancelling,
            1,
            "should be 1 as it closes not deleted"
        );

        assertEq(
            AfterFundbalanceOfPot,
            1e15,
            "As funded using the fundContest Function"
        );
        assertLe(
            balanceOfUSerAfterClosingtheContest,
            balanceOfUserAfterFunding,
            "Should be less"
        );
    }

    function test_RevertIfNonPOwnerCallsTheCloseContest() public createContest {
        uint256 balanceOfPot = mERC20.balanceOf(address(createdContest));
        uint256 lengthOfTheContestBeforeCancelling = cmanager
            .getContests()
            .length;
        //Act
        cmanager.fundContest(0);

        uint256 AfterFundbalanceOfPot = mERC20.balanceOf(
            address(createdContest)
        );

        uint256 balanceOfUserAfterFunding = mERC20.balanceOf(default_Foundry);

        vm.warp(block.timestamp + 91 days);
        vm.expectRevert();
        vm.startPrank(spider);
        cmanager.closeContest(address(createdContest));
        vm.stopPrank();
        uint256 lengthOfTheContestAfterCancelling = cmanager
            .getContests()
            .length;

        uint256 balanceOfUSerAfterClosingtheContest = mERC20.balanceOf(
            default_Foundry
        );
    }
}

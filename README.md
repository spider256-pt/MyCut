# First Flight #23: MyCut

### Prize Pool

- High - 100 XP
- Medium - 20 XP
- Low - 2 XP

- Starts: August, 29 2024 Noon UTC

- Ends: September 05, 2024 Noon UTC

- nSLOC: 106

[//]: # (contest-details-open)

## About the Project

MyCut is a contest rewards distribution protocol which allows the set up and management of multiple rewards distributions, allowing authorized claimants 90 days to claim before the manager takes a cut of the remaining pool and the remainder is distributed equally to those who claimed in time!

### Actors

- Owner/Admin (Trusted) - Is able to create new Pots, close old Pots when the claim period has elapsed and fund Pots
- User/Player - Can claim their cut of a Pot

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

All Contracts in `src` are in scope.

```js
src/
├── ContestManager.sol
├── Pot.sol
```

## Compatibilities

- Blockchains: EVM Equivalent Chains Only
- Tokens: Standard ERC20 Tokens Only


[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

Clone the repo
```bash
git clone https://github.com/Cyfrin/2024-08-MyCut.git
```
Open in VSCode
```bash
code 2024-08-MyCut/
```

Build and run tests
```bash
forge test
```


[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

## Finding- Missing Fund While Creating Contest
- Owner of the contest create a Contest using the ```createContest()``` function with some funds which are the total reward should be transferred to the Pot contract
- The issue arises as the total reward or funds never reached to the Pot contract when the ```createContest()``` function is called by the Owner. 

- As the contract ContestManager.sol
	- Have a Function Named createContest() which only can be called by the Owner using some parameters.
	
	```ContestManager.sol
    function createContest(
	address[] memory players,
	uint256[] memory rewards,
	IERC20 token,
	uint256 totalRewards
	) public onlyOwner returns (address) {
		// Create a new Pot contract
		Pot pot = new Pot(players, rewards, token, totalRewards);
		contests.push(address(pot));
		contestToTotalRewards[address(pot)] = totalRewards;
		return address(pot);
    }
    ```
    -  The parameter `totalRewards` is the total funds that should be transferred to the Pot contract as the Pot contract uses the same parameters to initialise or deploy itself using the createContest().
    - In Pot contract the transfer function is commented out by which its impossible to transfer the funds while creating the contest.

    - Pot.sol
    ```
    constructor(
        address[] memory players,
        uint256[] memory rewards,
        IERC20 token,
        uint256 totalRewards
    ) {
        i_players = players;
        i_rewards = rewards;
        i_token = token;
        i_totalRewards = totalRewards;
        remainingRewards = totalRewards;	
        i_deployedAt = block.timestamp;
	    // i_token.transfer(address(this), i_totalRewards);
	
	    for (uint256 i = 0; i < i_players.length; i++) {
		    playersToRewards[i_players[i]] = i_rewards[i];	
	    }
    }
    ```
    ## Risk
    - Lets say the creator or the owner creates a contest and set the total reward of 1e15.
    - As this is the ERC20 compatible contract the owner should have some tokens to create the contest 
    - let owner have 1e18 tokens and he created contest of 1e15 and calls the function createContest().
    - Because the transfer call is commented out, no tokens are ever deducted from the owner — their balance remains 1e18, confirmed by the PoC trace (`balanceOf(DefaultSender) → 1e18`). The Pot contract, however, is deployed believing it should hold 1e15 in rewards (per `remainingRewards` in storage), while its actual token balance is 0 — confirmed by the same trace (`balanceOf(Pot) → 0`).

    ## Impact 
    - Since `createContest()` never actually transfers `totalRewards` tokens into `Pot`, the contract becomes insolvent from the moment it's deployed, despite its storage claiming otherwise.
    - Any call to `claimCut()` will revert when `_transferReward` attempts to move tokens the contract doesn't have.
    - `closePot()` will similarly revert (or silently fail to pay out) for the same reason.
    - Players are misled into believing rewards are available (since `checkCut()` and `remainingRewards` report nonzero values), when in fact nothing can ever be claimed unless the Pot is separately funded after deployment — which the current contracts provide no clean mechanism for.

    ## POC

    - Testing the Missing funds while creating contest:
    ```solidity
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
    ```
    - Proof-Of-Concept 
   ```
        No files changed, compilation skipped
    Ran 1 test for test/POC/TestConstestManager.t.sol:TestContestManager
    [PASS] test_TrackFunds() (gas: 851915)
    Traces:
    [851915] TestContestManager::test_TrackFunds()
        ├─ [0] VM::startPrank(DefaultSender: [0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38])
        │   └─ ← [Return]
        ├─ [801485] ContestManager::createContest([0xB279F90f644e63EAca636d78E1d3fcC206632F63], [1000000000000000000 [1e18]], ERC20Mock: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 1000000000000000 [1e15])
        │   ├─ [694722] → new Pot@0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06
        │   │   ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: ContestManager: [0x34A1D3fff3958843C43aD80F30b94c510645C316])
        │   │   └─ ← [Return] 2663 bytes of code
        │   └─ ← [Return] Pot: [0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06]
        ├─ [2850] ERC20Mock::balanceOf(DefaultSender: [0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38]) [staticcall]
        │   └─ ← [Return] 1000000000000000000 [1e18]
        ├─ [917] ContestManager::getContestTotalRewards(Pot: [0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06]) [staticcall]
        │   └─ ← [Return] 1000000000000000 [1e15]
        ├─ [2850] ERC20Mock::balanceOf(Pot: [0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06]) [staticcall]
        │   └─ ← [Return] 0
        ├─ [0] VM::assertEq(0, 0, "should be 0") [staticcall]
        │   └─ ← [Return]
        ├─ [0] VM::stopPrank()
        │   └─ ← [Return]
        └─ ← [Stop]
        
    Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 8.34ms (771.42µs CPU time)
    Ran 1 test suite in 148.72ms (8.34ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```




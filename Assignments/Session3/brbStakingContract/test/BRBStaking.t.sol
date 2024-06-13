pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BRBStaking.sol";
import "../src/BRBToken.sol";

contract StakingContractTest is Test{
    BRBStaking stakingContract;
    BRBToken token;
    
    // Actors
    address owner;
    address user;

    function setUp() public {
        owner = address(0x111);
        user = address(0x222);

        vm.startPrank(owner);

        token = new BRBToken(owner);
        stakingContract = new BRBStaking(token);

        token.transfer(user, 1000 ether);
        vm.stopPrank();
    }

    // User should be able to initialize their staking profile - JUST ONCE
    function testInitializeUserTwice() public{

        vm.startPrank(user);
        stakingContract.initializeUser();

        vm.expectRevert("User already initialized");
        stakingContract.initializeUser();

        vm.stopPrank();
        
    }
    // TEST initializeUser() function
    function testInitializeUser() public {
        // Prank as user
        vm.prank(user);
        stakingContract.initializeUser();

        // Verify user initialization
        (address userAddress, , bool initialized, ,) = stakingContract.userStakeData(user, 0);
        assertEq(userAddress, user);
        assertTrue(initialized);
    }

    // Test stake() function
    function testStake() public {
        uint256 stakeAmount = 100 * 10**18;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);

        vm.stopPrank(); 
        // Verify staking
        (address userAddress, uint256 stakeAmountStored, bool initialized, ,uint256 stakeID) = stakingContract.userStakeData(user, 1);
        assertEq(userAddress, user);
        assertEq(stakeAmountStored, stakeAmount);
        assertEq(stakeID, 1);
        assertTrue(initialized);
    }

    // TEST unstake() function
    function testUnstakeFunction() public{
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardAmount = 100 * 10**18;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank(); 
        // Verify staking
        (address userAddress, uint256 stakeAmountStored, bool initialized, ,uint256 stakeID) = stakingContract.userStakeData(user, 1);

        // Owner Adds Reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Fast forward time by 7 days
        vm.warp(block.timestamp + 7 days);

        // Chck user balance before unstake
        uint256 userBalanceBefore = token.balanceOf(user);

        vm.startPrank(user);
        stakingContract.unstake(1);
        vm.stopPrank();

        // Check user balance after unstake 
        uint256 userBalanceAfter = token.balanceOf(user);
        // console.log(userBalanceBefore, userBalanceAfter, stakeAmount, rewardAmount);
        assertEq(userBalanceAfter, userBalanceBefore + stakeAmount + rewardAmount);
    }

    // TASKS TO DO for BRB DEVELOPERS
    // ToDo: Add test for addReward() function
    // ToDo: Add test for the following Checks:
    // 1. Only owner should be able to call the addRewards()
    // 2. Uninitialized User should not be able to STAKE or UNSTAKE
    // 3. Reward should exactly be 100 tokens for all stakers
    // 4. If a Staker tries to UNSTAKE before 7 days, it should revert
    // 5. Event Emission of Stake, Unstake and RewardAdded should be accurately tested
}
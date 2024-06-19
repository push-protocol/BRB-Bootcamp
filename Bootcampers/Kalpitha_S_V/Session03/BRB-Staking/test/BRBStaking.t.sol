// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BRBStaking.sol";
import "../src/BRBToken.sol";

contract StakingContractTest is Test {
    BRBStaking stakingContract;
    BRBToken token;
    
    // Actors
    address owner;
    address user;
    address anotherUser;

    function setUp() public {
        owner = address(0x111);
        user = address(0x222);
        anotherUser = address(0x333);

        vm.startPrank(owner);

        token = new BRBToken(owner);
        stakingContract = new BRBStaking(token);

        token.transfer(user, 1000 ether);
        token.transfer(anotherUser, 1000 ether);
        vm.stopPrank();
    }

    // User should be able to initialize their staking profile - JUST ONCE
    function testInitializeUserTwice() public {
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
        (address userAddress, uint256 stakeAmountStored, bool initialized, , uint256 stakeID) = stakingContract.userStakeData(user, 0);
        assertEq(userAddress, user);
        assertEq(stakeAmountStored, stakeAmount);
        assertEq(stakeID, 0);
        assertTrue(initialized);
    }

    // TEST unstake() function
    function testUnstakeFunction() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardAmount = 100 * 10**18;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank(); 
        // Verify staking
        (address userAddress, uint256 stakeAmountStored, bool initialized, , uint256 stakeID) = stakingContract.userStakeData(user, 0);

        // Owner Adds Reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Fast forward time by 7 days
        vm.warp(block.timestamp + 7 days);

        // Check user balance before unstake
        uint256 userBalanceBefore = token.balanceOf(user);

        vm.startPrank(user);
        stakingContract.unstake(0);
        vm.stopPrank();

        // Check user balance after unstake 
        uint256 userBalanceAfter = token.balanceOf(user);
        assertEq(userBalanceAfter, userBalanceBefore + stakeAmount + rewardAmount);
    }

    // Test for addReward() function
    function testAddReward() public {
        uint256 rewardAmount = 100 * 10**18;

        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);

        uint256 contractBalance = token.balanceOf(address(stakingContract));
        assertEq(contractBalance, rewardAmount);
        vm.stopPrank();
    }

    // Only owner should be able to call addReward()
    function testOnlyOwnerCanAddReward() public {
        uint256 rewardAmount = 100 * 10**18;

        vm.startPrank(user);
        token.approve(address(stakingContract), rewardAmount);
        vm.expectRevert("Ownable: caller is not the owner");
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();
    }

    // Uninitialized user should not be able to stake or unstake
    function testUninitializedUserCannotStakeOrUnstake() public {
        uint256 stakeAmount = 100 * 10**18;

        // User tries to stake without initialization
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        vm.expectRevert("User not initialized");
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // User tries to unstake without initialization
        vm.startPrank(user);
        vm.expectRevert("User not initialized");
        stakingContract.unstake(0);
        vm.stopPrank();
    }

    // Reward should be exactly 100 tokens for all stakers
    function testRewardDistribution() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardAmount = 100 * 10**18;

        // Owner adds reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // User stakes tokens
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Fast forward time by 7 days
        vm.warp(block.timestamp + 7 days);

        // User unstakes tokens
        vm.startPrank(user);
        stakingContract.unstake(0);
        vm.stopPrank();

        uint256 userBalanceAfter = token.balanceOf(user);
        assertEq(userBalanceAfter, 1000 ether + rewardAmount); // Initial balance + reward
    }

    // If a staker tries to unstake before 7 days, it should revert
    function testUnstakeBefore7Days() public {
        uint256 stakeAmount = 100 * 10**18;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Try to unstake before 7 days
        vm.startPrank(user);
        vm.expectRevert("Cannot unstake before 7 days");
        stakingContract.unstake(0);
        vm.stopPrank();
    }

    // Test event emissions for Stake, Unstake, and RewardAdded
    function testEventEmissions() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardAmount = 100 * 10**18;

        // Test Stake event
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        vm.expectEmit(true, true, true, true);
        emit stakingContract.Stake(user, 0, stakeAmount);
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Test RewardAdded event
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        vm.expectEmit(true, true, true, true);
        emit stakingContract.RewardAdded(rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Test Unstake event
        vm.warp(block.timestamp + 7 days);
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit stakingContract.Unstake(user, 0, stakeAmount, rewardAmount);
        stakingContract.unstake(0);
        vm.stopPrank();
    }
}

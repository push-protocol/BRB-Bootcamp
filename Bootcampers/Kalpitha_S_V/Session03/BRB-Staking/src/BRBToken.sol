pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "..Session03/BRB-Staking/src/BRBStaking.sol";
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
        stakingContract.unstake(1);
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
        stakingContract.unstake(1);
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
        stakingContract.unstake(1);
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
        emit Stake(user, 1, stakeAmount);
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Test RewardAdded event
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        vm.expectEmit(true, true, true, true);
        emit RewardAdded(rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Test Unstake event
        vm.warp(block.timestamp + 7 days);
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit Unstake(user, 1, stakeAmount, rewardAmount);
        stakingContract.unstake(1);
        vm.stopPrank();
    }
}

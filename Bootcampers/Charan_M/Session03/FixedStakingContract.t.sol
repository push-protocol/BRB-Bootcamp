// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BRBStaking.sol";
import "../src/BRBToken.sol";

contract StakingContractTest is Test {
    BRBStaking stakingContract;
    BRBToken token;

    event TokensStaked(address indexed user, uint256 amount, uint256 stakeID);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 stakeID);
    event RewardsAdded(uint256 amount);

    address owner;
    address user;
    address user2;

    function setUp() public {
        owner = address(0x111);
        user = address(0x222);
        user2 = address(0x333);

        vm.startPrank(owner);
        token = new BRBToken(owner);
        stakingContract = new BRBStaking(token);
        token.transfer(user, 1000 ether);
        token.transfer(user2, 1000 ether);
        vm.stopPrank();
    }

    function testInitializeUserTwice() public {
            vm.startPrank(user);
            stakingContract.initializeUser();

            vm.expectRevert("User already initialized");
            stakingContract.initializeUser();
            vm.stopPrank();
        }

        function testInitializeUser() public {
        vm.prank(user);
        stakingContract.initializeUser();

        (uint256 stakeAmount, uint256 timeStamp, address userAddress, uint8 stakeID, bool initialized) = stakingContract.userStakeData(user, 0);
        assertEq(userAddress, user);
        assertTrue(initialized);
        assertEq(stakeAmount, 0);
        assertEq(timeStamp, 0);
        assertEq(stakeID, 0);
    }

    function testStake() public {
        uint256 stakeAmount = 100 ether;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        (uint256 storedStakeAmount, uint256 timeStamp, address userAddress, uint8 stakeID, bool initialized) = stakingContract.userStakeData(user, 1);
        assertEq(userAddress, user);
        assertEq(storedStakeAmount, stakeAmount);
        assertEq(stakeID, 1);
        assertTrue(initialized);
        assertGt(timeStamp, 0);
    }

    function testUnstakeFunction() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 100 ether;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        uint256 userBalanceBefore = token.balanceOf(user);

        vm.prank(user);
        stakingContract.unstake(1);

        uint256 userBalanceAfter = token.balanceOf(user);
        assertEq(userBalanceAfter, userBalanceBefore + stakeAmount + rewardAmount);
    }

    function testAddReward() public {
        uint256 rewardAmount = 100 ether;
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        assertEq(stakingContract.rewardPool(), rewardAmount);
    }

    function testUnstakeBeforeTime() public {
        uint256 stakeAmount = 100 ether;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);

        vm.expectRevert("Lockup period not completed");
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    function testEmitStakeEvent() public {
        vm.startPrank(user);
        token.approve(address(stakingContract), 100 ether);
        stakingContract.initializeUser();

        vm.expectEmit(true, true, true, true);
        emit TokensStaked(user, 100 ether, 1);
        stakingContract.stake(100 ether);
        vm.stopPrank();
    }

    function testEmitUnstakeEvent() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 100 ether;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit TokensUnstaked(user, stakeAmount + rewardAmount, 1);
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    function testEmitRewardEvent() public {
        uint256 rewardAmount = 100 ether;
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        vm.expectEmit(true, true, true, true);
        emit RewardsAdded(rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();
    }

    //  1. Only owner should be able to call the addRewards()
    function testOnlyOwnerCanAddRewards() public {
        uint256 rewardAmount = 100 ether;
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        stakingContract.addReward(rewardAmount);
    }

    // 2. Uninitialized User should not be able to STAKE
    function testUninitializedUserCannotStake() public {
        uint256 stakeAmount = 100 ether;
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        vm.expectRevert("User not initialized");
        stakingContract.stake(stakeAmount);
        vm.stopPrank();
    }

    // 2. Uninitialized User should not be able to UNSTAKE
    function testUninitializedUserCannotUnstake() public {
        vm.prank(user);
        vm.expectRevert("User not Initialized");
        stakingContract.unstake(1);
    }

    // 3. Reward should exactly be 100 tokens for all stakers  

    function testRewardDistribution() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 100 ether;

        // User 1 stakes
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // User 2 stakes
        vm.startPrank(user2);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Add reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        // User 1 unstakes
        uint256 user1BalanceBefore = token.balanceOf(user);
        vm.prank(user);
        stakingContract.unstake(1);
        uint256 user1BalanceAfter = token.balanceOf(user);
        uint256 user1Reward = user1BalanceAfter - user1BalanceBefore - stakeAmount;

        // User 2 unstakes
        uint256 user2BalanceBefore = token.balanceOf(user2);
        vm.prank(user2);
        stakingContract.unstake(1);
        uint256 user2BalanceAfter = token.balanceOf(user2);
        uint256 user2Reward = user2BalanceAfter - user2BalanceBefore - stakeAmount;

        // Check that rewards are distributed equally
        assertEq(user1Reward, rewardAmount / 2);
        assertEq(user2Reward, rewardAmount / 2);
    }

    // 4. If a Staker tries to UNSTAKE before 7 days, it should revert
    function testUnstakeBeforeLockupPeriod() public {
        uint256 stakeAmount = 100 ether;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);

        // Try to unstake before the lockup period (7 days)
        vm.expectRevert("Lockup period not completed");
        stakingContract.unstake(1);

        vm.stopPrank();
    }

    // 5. Event Emission of Stake, Unstake, and RewardAdded should be accurately tested
    function testEventEmission() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 50 ether;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();

        // Stake and check for event
        vm.expectEmit(true, true, true, true);
        emit TokensStaked(user, stakeAmount, 1);
        stakingContract.stake(stakeAmount);

        vm.stopPrank();

        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);

        // Add reward and check for event
        vm.expectEmit(true, true, true, true);
        emit RewardsAdded(rewardAmount);
        stakingContract.addReward(rewardAmount);

        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        vm.startPrank(user);

        // Unstake and check for event
        vm.expectEmit(true, true, true, true);
        emit TokensUnstaked(user, stakeAmount + rewardAmount, 1); // Assuming all reward goes to this user
        stakingContract.unstake(1);

        vm.stopPrank();
    }
}
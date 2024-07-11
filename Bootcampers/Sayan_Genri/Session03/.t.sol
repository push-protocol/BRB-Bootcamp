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
        (address userAddress, bool initialized, , , ) = stakingContract.userStakeData(user, 0);
        assertEq(userAddress, user);
        assertTrue(initialized);
    }

    // Test stake() function
    function testStake() public {
        uint256 stakeAmount = 100 ether;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Verify staking
        (address userAddress, bool initialized, uint256 stakeID, uint256 stakeAmountStored, ) = stakingContract.userStakeData(user, 1);
        assertEq(userAddress, user);
        assertEq(stakeAmountStored, stakeAmount);
        assertEq(stakeID, 1);
        assertTrue(initialized);
    }

    // TEST unstake() function
    function testUnstakeFunction() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 100 ether;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

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
        stakingContract.unstake(1);
        vm.stopPrank();

        // Check user balance after unstake
        uint256 userBalanceAfter = token.balanceOf(user);
        assertEq(userBalanceAfter, userBalanceBefore + stakeAmount + rewardAmount);
    }

    // Test addReward() function
    function testAddReward() public {
        vm.startPrank(owner);
        token.approve(address(stakingContract), 100 ether);
        stakingContract.addReward(100 ether);
        vm.stopPrank();

        assertEq(stakingContract.rewardPool(), 100 ether);
    }

    // TEST addReward() function ownership check
    function testAddRewardOwnership() public {
        uint256 rewardAmount = 100 ether;

        // Non-owner tries to add reward
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Owner adds reward successfully
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();
    }

    // TEST uninitialized user cannot stake
    function testUninitializedUserCannotStake() public {
        uint256 stakeAmount = 100 ether;

        // User tries to stake without initializing
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        vm.expectRevert("User not initialized");
        stakingContract.stake(stakeAmount);
        vm.stopPrank();
    }

    // TEST uninitialized user cannot unstake
    function testUninitializedUserCannotUnstake() public {
        // User tries to unstake without initializing
        vm.startPrank(user);
        vm.expectRevert("User not initialized");
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    // TEST Reward Distribution
    function testRewardDistribution() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 100 ether;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Prank as owner to add reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Fast forward time by 7 days
        vm.warp(block.timestamp + 7 days);

        // Unstake and verify reward
        vm.startPrank(user);
        stakingContract.unstake(1);
        vm.stopPrank();

        // Check user balance after unstake
        uint256 userBalanceAfter = token.balanceOf(user);
        assertEq(userBalanceAfter, 100 ether + 100 ether, "Reward distribution failed");
    }

    // TEST Unstake before lockup period
    function testUnstakeBeforeLockupPeriod() public {
        uint256 stakeAmount = 100 ether;

        // Prank as user to stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Try to unstake before 7 days
        vm.startPrank(user);
        vm.expectRevert("Lockup period not completed");
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    // Test event emission for TokensStaked
    function testTokensStakedEvent() public {
        uint256 stakeAmount = 100 ether;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        vm.expectEmit(true, true, false, true);
        emit TokensStaked(user, stakeAmount, 1);
        stakingContract.stake(stakeAmount);
        vm.stopPrank();
    }

    // Test event emission for TokensUnstaked
    function testTokensUnstakedEvent() public {
        uint256 stakeAmount = 100 ether;
        uint256 rewardAmount = 100 ether;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Owner Adds Reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Fast forward time by 7 days
        vm.warp(block.timestamp + 7 days);

        // Prank as user to unstake
        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit TokensUnstaked(user, stakeAmount + rewardAmount, 1);
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    // Test event emission for RewardsAdded
    function testRewardsAddedEvent() public {
        uint256 rewardAmount = 100 ether;

        // Prank as owner to add reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        vm.expectEmit(true, true, false, true);
        emit RewardsAdded(rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();
    }
}

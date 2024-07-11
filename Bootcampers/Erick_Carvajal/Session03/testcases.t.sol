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
        (address userAddress, , bool initialized, , ) = stakingContract.userStakeData(user, 0);
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
        (address userAddress, uint256 stakeAmountStored, bool initialized, , uint256 stakeID) = stakingContract.userStakeData(user, 1);
        assertEq(userAddress, user);
        assertEq(stakeAmountStored, stakeAmount);
        assertEq(stakeID, 1);
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
        uint256 rewardAmount = 100 * 10**18;

        // Owner adds reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Verify reward pool
        assertEq(stakingContract.rewardPool(), rewardAmount);
    }

    // Test that only owner can call addReward()
    function testOnlyOwnerCanAddReward() public {
        uint256 rewardAmount = 100 * 10**18;

        vm.startPrank(user);
        token.approve(address(stakingContract), rewardAmount);
        vm.expectRevert("Ownable: caller is not the owner");
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();
    }

    // Test that uninitialized user cannot stake
    function testUninitializedUserCannotStake() public {
        uint256 stakeAmount = 100 * 10**18;

        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        vm.expectRevert("User not initialized");
        stakingContract.stake(stakeAmount);
        vm.stopPrank();
    }

    // Test that uninitialized user cannot unstake
    function testUninitializedUserCannotUnstake() public {
        vm.startPrank(user);
        vm.expectRevert("Stake not found");
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    // Test that reward is exactly 100 tokens for all stakers
    function testExactRewardForStakers() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardAmount = 100 * 10**18;

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

    // Test that unstake before 7 days reverts
    function testUnstakeBeforeLockupReverts() public {
        uint256 stakeAmount = 100 * 10**18;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Try to unstake before 7 days
        vm.warp(block.timestamp + 6 days);
        vm.startPrank(user);
        vm.expectRevert("Lockup period not completed");
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    // Test event emission for stake
    function testStakeEventEmission() public {
        uint256 stakeAmount = 100 * 10**18;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();

        vm.expectEmit(true, true, true, true);
        emit stakingContract.TokensStaked(user, stakeAmount, 1);
        stakingContract.stake(stakeAmount);
        vm.stopPrank();
    }

    // Test event emission for unstake
    function testUnstakeEventEmission() public {
        uint256 stakeAmount = 100 * 10**18;
        uint256 rewardAmount = 100 * 10**18;

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

        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit stakingContract.TokensUnstaked(user, stakeAmount + rewardAmount, 1);
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    // Test event emission for addReward
    function testAddRewardEventEmission() public {
        uint256 rewardAmount = 100 * 10**18;

        // Owner adds reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);

        vm.expectEmit(true, true, true, true);
        emit stakingContract.RewardsAdded(rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();
    }
}

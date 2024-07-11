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
        (address userAddress, bool initialized, , , ) = stakingContract
            .userStakeData(user, 0);
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
        (
            address userAddress,
            bool initialized,
            uint256 stakeID,
            uint256 stakeAmountStored,

        ) = stakingContract.userStakeData(user, 1);
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
        // Verify staking


        // Owner Adds Reward
        vm.startPrank(owner);
        token.approve(address(stakingContract), rewardAmount);
        stakingContract.addReward(rewardAmount);
        vm.stopPrank();

        // Fast forward time by 7 days
        vm.startPrank(user);
        vm.expectRevert("Lockup period not completed");
        stakingContract.unstake(1);
        vm.stopPrank();
        vm.warp(block.timestamp + 7 days);

        // Chck user balance before unstake
        uint256 userBalanceBefore = token.balanceOf(user);

        vm.startPrank(user);
        stakingContract.unstake(1);
        vm.stopPrank();

        // Check user balance after unstake
        uint256 userBalanceAfter = token.balanceOf(user);
        // console.log(userBalanceBefore, userBalanceAfter, stakeAmount, rewardAmount);
        assertEq(
            userBalanceAfter,
            userBalanceBefore + stakeAmount + rewardAmount
        );
    }

    function testAddReward() public {
        vm.startPrank(owner);
        token.approve(address(stakingContract), 100 ether);
        stakingContract.addReward(100 ether);
        vm.stopPrank();
    }

    //4. If a Staker tries to UNSTAKE before 7 days, it should revert
    function testUnstakeBeforeTime() public {
        uint256 stakeAmount = 100 ether;

        // Prank as user to approve and stake
        vm.startPrank(user);
        token.approve(address(stakingContract), stakeAmount);
        stakingContract.initializeUser();
        stakingContract.stake(stakeAmount);
        vm.stopPrank();

        // Unstaking before 7 days
        vm.startPrank(user);
        vm.expectRevert("Lockup period not completed");
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    // 5. Event Emission of Stake, Unstake and RewardAdded should be accurately tested
    function testEmitStakeEvent() public {
        vm.startPrank(user);
        token.approve(address(stakingContract), 100 ether);
        stakingContract.initializeUser();

        vm.expectEmit(true, false, false, false);
        emit TokensStaked(user, 50, 1);
        stakingContract.stake(100 ether);
    }

    function testEmitUnstakeEvent() public {
        vm.startPrank(user);
        token.approve(address(stakingContract), 100 ether);
        stakingContract.initializeUser();
        stakingContract.stake(100 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        token.approve(address(stakingContract), 100 ether);
        stakingContract.addReward(100 ether);
        vm.stopPrank();

        // Fast forward time by 7 days
        vm.warp(block.timestamp + 7 days);

        vm.startPrank(user);
        vm.expectEmit(true, false, true, false);
        emit TokensUnstaked(user, 50, 1);
        stakingContract.unstake(1);
        vm.stopPrank();
    }

    function testEmitRewardEvent() public {
        vm.startPrank(owner);
        token.approve(address(stakingContract), 100 ether);
        vm.expectEmit(true, false, false, false);
        emit RewardsAdded(50);
        stakingContract.addReward(100 ether);
        vm.stopPrank();
    }

    // TASKS TO DO for BRB DEVELOPERS
    // ToDo: Add test for addReward() function
    // Test addReward() function
    function testAddReward() public {
    uint256 rewardAmount = 100 * 10**18;

    // Prank as owner to add reward
    vm.startPrank(owner);
    token.approve(address(stakingContract), rewardAmount);
    stakingContract.addReward(rewardAmount);

    // Verify reward pool
    assertEq(stakingContract.rewardPool(), rewardAmount);

    vm.stopPrank();
}



    // ToDo: Add test for the following Checks:
    // 1. Only owner should be able to call the addRewards()
// 


// TEST addReward() function ownership check
function testAddRewardOwnership() public {
    uint256 rewardAmount = 100 * 10**18;

    // Non-owner tries to add reward
    // vm.startPrank(user);
    // vm.expectRevert(bytes4(keccak256("Ownable: caller is not the owner")));
    // stakingContract.addReward(rewardAmount);
    // vm.stopPrank();

    // Owner adds reward successfully
    vm.startPrank(user);
    token.approve(address(stakingContract), rewardAmount);
    stakingContract.addReward(rewardAmount);
    vm.stopPrank();
}

    // 2. Uninitialized User should not be able to STAKE or UNSTAKE
    // TEST uninitialized user cannot stake
function testUninitializedUserCannotStake() public {
    uint256 stakeAmount = 100 * 10**18;

    // User tries to stake without initializing
    vm.startPrank(user);
    token.approve(address(stakingContract), stakeAmount);
    vm.expectRevert("User not initialized");
    stakingContract.stake(stakeAmount);
    vm.stopPrank();
}

// TEST uninitialized user cannot unstake
function testUninitializedUserCannotUnstake() public {
    // uint256 stakeAmount = 100 * 10**18;

    // User tries to unstake without initializing
    vm.startPrank(user);
    vm.expectRevert("Stake not found");
    stakingContract.unstake(1);
    vm.stopPrank();
}


    // 3. Reward should exactly be 100 tokens for all stakers
 
        // TEST Reward Distribution
function testRewardDistribution() public {


    // Set up stake and reward amounts
    uint256 stakeAmount = 100 ether;
    uint256 rewardAmount = 100 ether;

    // // Set up user and owner
    // address user1 = address(0x1);
    // address owner1 = address(0x2);
    uint256 userBalanceBefore = token.balanceOf(user);

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
    vm.expectEmit(true, true, false, true);
    emit TokensUnstaked(user, stakeAmount + rewardAmount, 1);
    stakingContract.unstake(1);
    vm.stopPrank();

    // Check user balance after unstake 
    uint256 userBalanceAfter = token.balanceOf(user);

    // Verify reward is exactly 200 tokens
    assertEq(userBalanceAfter, userBalanceBefore + rewardAmount, "Reward distribution failed");
}



    // 4. If a Staker tries to UNSTAKE before 7 days, it should revert

    function testUnstakeBeforeLockupPeriod() public {
    uint256 stakeAmount = 100 * 10**18;

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


    // 5. Event Emission of Stake, Unstake and RewardAdded should be accurately tested


    // Test event emission for TokensStaked
function testTokensStakedEvent() public {
    uint256 stakeAmount = 100 * 10**18;

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

    // Prank as user to unstake
    vm.startPrank(user);
    vm.expectEmit(true, true, false, true);
    emit TokensUnstaked(user, stakeAmount + rewardAmount, 1);
    stakingContract.unstake(1);
    vm.stopPrank();
}

// Test event emission for RewardsAdded
function testRewardsAddedEvent() public {
    uint256 rewardAmount = 100 * 10**18;

    // Prank as owner to add reward
    vm.startPrank(owner);
    token.approve(address(stakingContract), rewardAmount);
    vm.expectEmit(true, true, false, true);
    emit RewardsAdded(rewardAmount);
    stakingContract.addReward(rewardAmount);
    vm.stopPrank();
}


}


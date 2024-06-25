pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BRBStakingForTest.sol"; // The original contract BRBStaking was changed to BRBStakingForTest to prevent draining and ensure users receive only 100 tokens.
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
        assertFalse(rewardReceived);  // Verify rewardReceived is false
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

    function testOnlyOwnerCanAddReward() public {
    uint256 rewardAmount = 200 * 10**18;

    // Attempt to add reward as non-owner (should fail)
    vm.startPrank(user);
    token.approve(address(stakingContract), rewardAmount);
    vm.expectRevert("Ownable: caller is not the owner");
    stakingContract.addReward(rewardAmount);
    vm.stopPrank();

    // Add reward as owner (should succeed)
    vm.startPrank(owner);
    token.approve(address(stakingContract), rewardAmount);
    stakingContract.addReward(rewardAmount);
    vm.stopPrank();

    // Verify reward pool update
    assertEq(stakingContract.rewardPool(), rewardAmount);
    }

    // 2. Uninitialized User should not be able to STAKE or UNSTAKE

    function testUninitializedUserCannotStakeOrUnstake() public {
    uint256 stakeAmount = 100 * 10**18;

    // Attempt to stake without initialization (should revert)
    vm.startPrank(user);
    token.approve(address(stakingContract), stakeAmount);
    vm.expectRevert("User not initialized");
    stakingContract.stake(stakeAmount);

    // Attempt to unstake without initialization (should revert)
    vm.expectRevert("User not initialized");
    stakingContract.unstake(2); // Using 2 as an example stakeID
    vm.stopPrank();
    }

    // 3. Reward should exactly be 100 tokens for all stakers

    function testRewardIsExactly100TokensPerUser() public {
    uint256 stakeAmount = 50 * 10**18;  // Example stake amount, can be any value
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

    // Check user balance before first unstake
    uint256 userBalanceBefore = token.balanceOf(user);

    // First unstake and check reward
    vm.startPrank(user);
    stakingContract.unstake(1);
    vm.stopPrank();

    // Check user balance after first unstake
    uint256 userBalanceAfter = token.balanceOf(user);
    assertEq(userBalanceAfter, userBalanceBefore + stakeAmount + rewardAmount);

    // Verify that the user has received the reward
    (, , , , , bool rewardReceived) = stakingContract.userStakeData(user, 1);
    assertTrue(rewardReceived);

    // Attempt to unstake again immediately and expect revert due to maximum reward received
    vm.startPrank(user);
    vm.expectRevert("User has already received the maximum reward");
    stakingContract.unstake(1);  // Trying to unstake the same stake ID again
    vm.stopPrank();

    // Verify that the balance has not changed since the second unstake failed
    userBalanceAfter = token.balanceOf(user);
    assertEq(userBalanceAfter, userBalanceBefore + stakeAmount + rewardAmount);
    }

    // 4. If a Staker tries to UNSTAKE before 7 days, it should revert

    function testUnstakeBefore7DaysReverts() public {
    uint256 stakeAmount = 100 * 10**18;

    // Prank as user to approve and stake
    vm.startPrank(user);
    token.approve(address(stakingContract), stakeAmount);
    stakingContract.initializeUser();
    stakingContract.stake(stakeAmount);
    vm.stopPrank();

    // Attempt to unstake before 7 days
    vm.startPrank(user);
    vm.expectRevert("Lockup period not completed");
    stakingContract.unstake(1);
    vm.stopPrank();
    }


    // 5. Event Emission of Stake, Unstake and RewardAdded should be accurately tested

    // TEST: Event emission for stake()

    function testStakeEvent() public {
    uint256 stakeAmount = 100 * 10**18;

    // Prank as user to approve and stake
    vm.startPrank(user);
    token.approve(address(stakingContract), stakeAmount);
    stakingContract.initializeUser();

    // Set expectation for TokensStaked event
    vm.expectEmit(true, true, true, true);
    emit TokensStaked(user, stakeAmount, 1);

    stakingContract.stake(stakeAmount);
    vm.stopPrank();
    }

    // TEST: Event emission for unstake()

    function testUnstakeEvent() public {
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

    // Set expectation for TokensUnstaked event
    vm.startPrank(user);
    vm.expectEmit(true, true, true, true);
    emit TokensUnstaked(user, stakeAmount + rewardAmount, 1);

    stakingContract.unstake(1);
    vm.stopPrank();
    }


    // TEST: Event emission for RewardsAdded()

    function testRewardAddedEvent() public {
    uint256 rewardAmount = 200 * 10**18;

    // Set expectation for RewardsAdded event
    vm.startPrank(owner);
    token.approve(address(stakingContract), rewardAmount);

    vm.expectEmit(true, true, true, true);
    emit RewardsAdded(rewardAmount);

    stakingContract.addReward(rewardAmount);
    vm.stopPrank();
    }

}
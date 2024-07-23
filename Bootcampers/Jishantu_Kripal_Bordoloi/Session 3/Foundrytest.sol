// Actors
address owner;
address user;
address uninitializedUser;

// Constants
uint256 constant rewardAmount = 100 * 10**18;

function setUp() public {
    owner = address(0x111);
    user = address(0x222);
    uninitializedUser = address(0x333);

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
    (address userAddress, , bool initialized, ,) = stakingContract.userStakeData(user, 0);
    assertEq(userAddress, user);
    assertTrue(initialized);
}

// Test stake() function
function testStake() public {
    uint256 stakeAmount = 100 * 10**18;

    // User to approve and stake
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
function testUnstakeFunction() public {
    uint256 stakeAmount = 100 * 10**18;

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

// Test that only the owner can call addReward()
function testAddRewardOwnership() public {
    uint256 amountToAdd = 200 * 10**18;

    // Attempt to call addReward by a non-owner should revert
    vm.startPrank(user);
    vm.expectRevert("Ownable: caller is not the owner");
    stakingContract.addReward(amountToAdd);
    vm.stopPrank();

    // Owner should be able to call addReward
    vm.startPrank(owner);
    token.approve(address(stakingContract), amountToAdd);
    stakingContract.addReward(amountToAdd);
    vm.stopPrank();
}

// Test that uninitialized user cannot stake or unstake
function testUninitializedUserRestrictions() public {
    uint256 stakeAmount = 50 * 10**18;

    vm.startPrank(uninitializedUser);

    // Approve tokens for staking
    token.approve(address(stakingContract), stakeAmount);

    // Try to stake without initializing
    vm.expectRevert("User not initialized");
    stakingContract.stake(stakeAmount);

    // Try to unstake without initializing or staking
    vm.expectRevert("User not initialized");
    stakingContract.unstake(1);

    vm.stopPrank();
}

// Test that reward is exactly 100 tokens for all stakers
function testRewardDistribution() public {
    uint256 stakeAmount = 100 * 10**18;

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
    stakingContract.unstake(1);
    vm.stopPrank();

    // Check final balance should be the initial balance + stake + reward
    uint256 finalBalance = token.balanceOf(user);
    assertEq(finalBalance, 1000 ether + rewardAmount); // Initial balance is 1000 ether
}

// Test that unstaking before 7 days should revert
function testUnstakeBefore7Days() public {
    uint256 stakeAmount = 100 * 10**18;

    // Prank as user to approve and stake
    vm.startPrank(user);
    token.approve(address(stakingContract), stakeAmount);
    stakingContract.initializeUser();
    stakingContract.stake(stakeAmount);
    vm.stopPrank(); 

    // Try to unstake before 7 days
    vm.startPrank(user);
    vm.expectRevert("Staking period not yet completed");
    stakingContract.unstake(1);
    vm.stopPrank();
}

// Test event emissions
function testEventEmissions() public {
    uint256 stakeAmount = 100 * 10**18;

    vm.startPrank(user);
    token.approve(address(stakingContract), stakeAmount);
    stakingContract.initializeUser();

    // Expect Stake event
    vm.expectEmit(true, true, true, true);
    emit Stake(user, stakeAmount, 1);
    stakingContract.stake(stakeAmount);

    vm.stopPrank();

    // Owner Adds Reward
    vm.startPrank(owner);
    token.approve(address(stakingContract), rewardAmount);

    // Expect RewardAdded event
    vm.expectEmit(true, true, true, true);
    emit RewardAdded(owner, rewardAmount);
    stakingContract.addReward(rewardAmount);
    vm.stopPrank();

    // Fast forward time by 7 days
    vm.warp(block.timestamp + 7 days);

    vm.startPrank(user);

    // Expect Unstake event
    vm.expectEmit(true, true, true, true);
    emit Unstake(user, 1);
    stakingContract.unstake(1);
    vm.stopPrank();
}

// Add the missing event definitions
event Stake(address indexed user, uint256 amount, uint256 indexed stakeID);
event Unstake(address indexed user, uint256 indexed stakeID);
event RewardAdded(address indexed owner, uint256 amount);

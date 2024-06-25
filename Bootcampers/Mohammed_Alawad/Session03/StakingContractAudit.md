# Audit Report: BRBStaking Contract


## Issues Identified

### 1. Reentrancy Vulnerability in `unstake` Function

#### Description:
The `unstake` function does not implement proper reentrancy protection.

#### Impact: High
A malicious user can exploit this vulnerability to call the `unstake` function recursively before the state is updated, potentially draining the contract of its funds.

#### Proof of Concept:
```solidity
function unstake(uint256 _stakeID) external {
    User storage user = userStakeData[msg.sender][_stakeID];
    require(user.initialized, "Stake not found");
    require(block.timestamp >= user.timeStamp + LOCKUP_PERIOD, "Lockup period not completed");

    totalStaked -= user.stakeAmount;

    if (rewardPool >= REWARD_AMOUNT) {
        user.stakeAmount += REWARD_AMOUNT;
        rewardPool -= REWARD_AMOUNT;
    }

    // Reentrancy vulnerability here
    token.transfer(msg.sender, user.stakeAmount);

    emit TokensUnstaked(msg.sender, user.stakeAmount, _stakeID);

    delete userStakeData[msg.sender][_stakeID];
}
```

#### Recommended Mitigation:
Use the checks-effects-interactions pattern to prevent reentrancy.
```solidity
function unstake(uint256 _stakeID) external nonReentrant {
    User storage user = userStakeData[msg.sender][_stakeID];
    require(user.initialized, "Stake not found");
    require(block.timestamp >= user.timeStamp + LOCKUP_PERIOD, "Lockup period not completed");

    uint256 amount = user.stakeAmount;

    totalStaked -= amount;

    if (rewardPool >= REWARD_AMOUNT) {
        amount += REWARD_AMOUNT;
        rewardPool -= REWARD_AMOUNT;
    }

    delete userStakeData[msg.sender][_stakeID];

    token.transfer(msg.sender, amount);

    emit TokensUnstaked(msg.sender, amount, _stakeID);
}
```

### 2. Unrestricted `addReward` Function

#### Description:
The `addReward` function is callable by any account, not just the owner.

#### Impact: Medium
An attacker could call this function to manipulate the reward pool, potentially leading to unexpected behavior or loss of funds.

#### Proof of Concept:
```solidity
function addReward(uint256 _amount) external {
    require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    rewardPool += _amount;

    emit RewardsAdded(_amount);
}
```

#### Recommended Mitigation:
Restrict the `addReward` function to only the owner.
```solidity
function addReward(uint256 _amount) external onlyOwner {
    require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    rewardPool += _amount;

    emit RewardsAdded(_amount);
}
```

### 3. Redundant rewardPool Check in `unstake`

#### Description:
The `unstake` function does not handle the situation where `rewardPool` is less than `REWARD_AMOUNT` correctly. It checks if `rewardPool` is sufficient but does not reflect the potential shortfall in the user's unstake amount calculation.

#### Impact: Medium
Users may not receive the expected rewards if the reward pool is insufficient, leading to unfair token distribution.

#### Proof of Concept:
```solidity
if (rewardPool >= REWARD_AMOUNT) {
    user.stakeAmount += REWARD_AMOUNT;
    rewardPool -= REWARD_AMOUNT;
}

If the rewardPool is less than REWARD_AMOUNT, no rewards are given, and the user's stake amount remains unchanged.
```

#### Recommended Mitigation:
Ensure rewards are added only if the rewardPool has sufficient tokens and adjust totalStaked correctly.
```solidity
uint256 amountToUnstake = user.stakeAmount;
if (rewardPool >= REWARD_AMOUNT) {
    amountToUnstake += REWARD_AMOUNT;
    rewardPool -= REWARD_AMOUNT;
}

totalStaked -= user.stakeAmount;
token.transfer(msg.sender, amountToUnstake);

emit TokensUnstaked(msg.sender, amountToUnstake, _stakeID);

delete userStakeData[msg.sender][_stakeID];
```


### 4. Lack of Input Validation

#### Description:
The `stake` function does not validate the `_amount` parameter to ensure it is greater than zero.

#### Impact: Low
Users can call the `stake` function with an `_amount` of zero, which could lead to unnecessary state changes and events, potentially cluttering the blockchain with invalid transactions.

#### Proof of Concept:
```solidity
function stake(uint256 _amount) external {
    require(userStakeData[msg.sender][0].initialized, "User not initialized");
    require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    // _amount is not validated
    uint8 stakeID = userStakeCount[msg.sender] + 1;

    User memory user;
    user.stakeAmount = _amount;
    user.userAddress = msg.sender;
    user.timeStamp = block.timestamp;
    user.stakeID = stakeID;
    user.initialized = true;

    userStakeData[msg.sender][stakeID] = user;

    userStakeCount[msg.sender]++;
    totalStaked += _amount;

    emit TokensStaked(msg.sender, _amount, stakeID);
}
```

#### Recommended Mitigation:
Add a check to ensure `_amount` is greater than zero.
```solidity
require(_amount > 0, "Stake amount must be greater than zero");
```

### 5. Inconsistent Event Emissions

#### Description:
The `initializeUser` function emits the `UserInitialized` event, but the `unstake` function does not emit an event for user deletion.

#### Impact: Low
Inconsistent event emissions can make it difficult to track state changes and debug issues.

#### Proof of Concept:
```solidity
function initializeUser() external {
    require(!userStakeData[msg.sender][0].initialized, "User already initialized");

    User memory user;
    user.userAddress = msg.sender;
    user.stakeAmount = 0;
    user.timeStamp = 0;
    user.stakeID = 0;
    user.initialized = true;

    userStakeData[msg.sender][0] = user;
    emit UserInitialized(msg.sender);
}
```

#### Recommended Mitigation:
Emit an event when a user is deleted in the `unstake` function.
```solidity
emit UserDeleted(msg.sender, _stakeID);
```

### 6. Incorrect Use of Struct Initialization

#### Description:
Struct fields are initialized manually, leading to potential errors and increased code complexity.

#### Impact: Low
Possible initialization errors and reduced code readability and maintainability.

#### Proof of Concept:
```solidity
User memory user;

user.userAddress = msg.sender;
user.stakeAmount = 0;
user.timeStamp = 0;
user.stakeID = 0;
user.initialized = true;

userStakeData[msg.sender][0] = user;
```

#### Recommended Mitigation:
Use a single line to initialize the struct.
```solidity
User memory user = User({
    userAddress: msg.sender,
    stakeAmount: 0,
    timeStamp: 0,
    stakeID: 0,
    initialized: true
});
userStakeData[msg.sender][0] = user;
```

### 7. Incorrect Mapping Declaration

#### Description:
The commented-out code indicates confusion about mapping usage, leading to potential maintenance issues.

#### Impact: Low
While there is no direct exploit, it suggests potential confusion and maintenance issues.

#### Proof of Concept:
```solidity
//mapping(address => mapping(uint256 => User)) public userStakeData;
mapping(address => mapping(uint256 => User)) public userStakeData;
```

#### Recommended Mitigation:
Remove the commented-out code for clarity.
```solidity
mapping(address => mapping(uint8 => User)) public userStakeData;
```


### 8. Inefficient Storage of Constants

#### Description:
`LOCKUP_PERIOD` and `REWARD_AMOUNT` are declared as mutable state variables instead of constants. This increases gas costs for every access.

#### Impact: Gas
Increased gas costs for every interaction with these variables.

#### Proof of Concept:
```solidity
uint256 public LOCKUP_PERIOD = 7 days; 
uint256 public REWARD_AMOUNT = 100 * 10 ** 18; 
```

Each access to these variables involves higher gas usage than necessary.

#### Recommended Mitigation:
Declare these variables as constants to reduce gas costs.
```solidity
uint256 public constant LOCKUP_PERIOD = 7 days; 
uint256 public constant REWARD_AMOUNT = 100 * 10 ** 18; 
```

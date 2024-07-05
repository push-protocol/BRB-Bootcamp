// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BRBStaking
 * @dev A contract that allows users to stake ERC20 tokens, earn rewards, and unstake after a lockup period.
 */
contract BRBStaking is Ownable {
    IERC20 public token;
    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public constant LOCKUP_PERIOD = 7 days;

    struct User {
        uint256 stakeAmount;
        uint256 timeStamp;
        address userAddress;
        uint8 stakeID;
        bool initialized;
    }

    mapping(address => mapping(uint256 => User)) public userStakeData;
    mapping(address => uint256) public userStakeCount;

    event UserInitialized(address indexed user);
    event TokensStaked(address indexed user, uint256 amount, uint256 stakeID);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 stakeID);
    event RewardsAdded(uint256 amount);

    constructor(IERC20 _token) Ownable(msg.sender) {
        require(address(_token) != address(0), "Invalid token address");
        token = _token;
    }

    function initializeUser() external {
        require(!userStakeData[msg.sender][0].initialized, "User already initialized");

        userStakeData[msg.sender][0] = User({
            stakeAmount: 0,
            timeStamp: 0,
            userAddress: msg.sender,
            stakeID: 0,
            initialized: true
        });
        emit UserInitialized(msg.sender);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Stake amount must be greater than 0");
        require(userStakeData[msg.sender][0].initialized, "User not initialized");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        uint256 stakeID = userStakeCount[msg.sender] + 1;
        userStakeData[msg.sender][stakeID] = User({
            stakeAmount: _amount,
            timeStamp: block.timestamp,
            userAddress: msg.sender,
            stakeID: uint8(stakeID),
            initialized: true
        });

        userStakeCount[msg.sender]++;
        totalStaked += _amount;

        emit TokensStaked(msg.sender, _amount, stakeID);
    }

    function unstake(uint256 _stakeID) external {
        User memory user = userStakeData[msg.sender][_stakeID];
        require(user.initialized, "User not Initialized");
        require(block.timestamp >= user.timeStamp + LOCKUP_PERIOD, "Lockup period not completed");

        uint256 amountToTransfer = user.stakeAmount;
        totalStaked -= user.stakeAmount;
        delete userStakeData[msg.sender][_stakeID];

        if (rewardPool > 0) {
            uint256 reward = (amountToTransfer * rewardPool) / totalStaked;
            amountToTransfer += reward;
            rewardPool -= reward;
        }

        emit TokensUnstaked(msg.sender, amountToTransfer, _stakeID);
        require(token.transfer(msg.sender, amountToTransfer), "Token transfer failed");
    }

    function addReward(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Reward amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        rewardPool += _amount;
        emit RewardsAdded(_amount);
    }
}
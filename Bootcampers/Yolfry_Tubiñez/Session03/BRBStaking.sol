// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title StakingContract
 * @dev A contract that allows users to stake ERC20 tokens, earn rewards, and unstake after a lockup period.
 */
contract BRBStaking is Ownable, ReentrancyGuard {
    IERC20 public token;
    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public constant LOCKUP_PERIOD = 7 days; 
    uint256 public constant REWARD_AMOUNT = 100 * 10 ** 18;

    /**
     * @dev Struct to represent a user's staking information.
     */

    struct User {
        uint256 stakeAmount;
        bool initialized;
        uint256 timeStamp; 
        uint8 stakeID; 
    }

     //mapping(address => mapping(uint256 => User)) public userStakeData;
    mapping(address => mapping(uint8 => User)) public userStakeData;
    mapping(address => uint8) public userStakeCount;

    /**
     * @dev Event emitted for various user actions.
     * @param user The address of the user.
     * @param action The action performed by the user.
     * @param amount The amount of tokens involved in the action.
     * @param stakeID The ID of the stake involved in the action.
     */

    event UserAction(address indexed user, string action, uint256 amount, uint256 stakeID);

    /**
     * @dev Constructor to initialize the staking contract with the token address.
     * @param _token The address of the ERC20 token to be staked.
     */
    constructor(IERC20 _token) Ownable() {
        token = _token;
    }

    /**
     * @notice Initializes the user's staking profile.
     */
    function initializeUser() public returns (bool) {
        User memory user;
        user.stakeAmount = 0;
        user.timeStamp = 0;
        user.stakeID = 0;
        user.initialized = true;

        userStakeData[msg.sender][0] = user;
        emit UserAction(msg.sender, "Initialized", 0, 0);
        return true;
    }

    /**
     * @notice Allows a user to stake tokens.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint256 _amount) external nonReentrant {
        require(userStakeData[msg.sender][0].initialized, "User not initialized");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        uint8 stakeID = userStakeCount[msg.sender] + 1;

        User memory user;
        user.stakeAmount = _amount;
        user.timeStamp = block.timestamp;
        user.stakeID = stakeID;
        user.initialized = true;

        userStakeData[msg.sender][stakeID] = user;

        userStakeCount[msg.sender]++;
        totalStaked += _amount;

        emit UserAction(msg.sender, "Staked", _amount, stakeID);
    }

    /**
     * @notice Allows a user to unstake tokens after the lockup period.
     * @param _stakeID The ID of the stake to unstake.
     */
    function unstake(uint256 _stakeID) external nonReentrant {
        User storage user = userStakeData[msg.sender][_stakeID];
        require(user.initialized, "Stake not found");
        require(block.timestamp >= user.timeStamp + LOCKUP_PERIOD, "Lockup period not completed");

        uint256 stakeAmount = user.stakeAmount;
        uint256 rewardAmount = 0;

        totalStaked -= stakeAmount;

        if (rewardPool >= REWARD_AMOUNT) {
            rewardAmount = REWARD_AMOUNT;
            rewardPool -= REWARD_AMOUNT;
        }

        uint256 totalAmount = stakeAmount + rewardAmount;
        token.transfer(msg.sender, totalAmount);

        emit UserAction(msg.sender, "Unstaked", totalAmount, _stakeID);

        delete userStakeData[msg.sender][_stakeID];
    }

    /**
     * @notice Adds rewards to the reward pool. Only callable by the admin.
     * @param _amount The amount of tokens to add to the reward pool.
     */
    function addReward(uint256 _amount) external nonReentrant {
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        rewardPool += _amount;
        emit UserAction(msg.sender, "RewardAdded", _amount, 0);
    }
}

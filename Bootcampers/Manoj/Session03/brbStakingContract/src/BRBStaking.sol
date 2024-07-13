// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

/**
 * @title StakingContract
 * @dev A contract that allows users to stake ERC20 tokens, earn rewards, and unstake after a lockup period.
 */
contract BRBStaking is Ownable {
    IERC20 public token;
    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public constant LOCKUP_PERIOD = 7 days;
    uint256 public constant REWARD_AMOUNT = 100 ether;

    /**
     * @dev Struct to represent a user's staking information.
     */
    struct User {
        address userAddress;
        bool initialized;
        uint8 stakeID;
        uint256 stakeAmount;
        uint256 timeStamp;
    }

    //mapping(address => mapping(uint256 => User)) public userStakeData;
    mapping(address => mapping(uint256 => User)) public userStakeData;
    mapping(address => uint8) public userStakeCount;

    /**
     * @dev Event emitted when a user initializes their staking profile.
     * @param user The address of the user.
     */
    event UserInitialized(address indexed user);

    /**
     * @dev Event emitted when a user stakes tokens.
     * @param user The address of the user.
     * @param amount The amount of tokens staked.
     * @param stakeID The ID of the stake.
     */
    event TokensStaked(address indexed user, uint256 amount, uint256 stakeID);

    /**
     * @dev Event emitted when a user unstakes tokens.
     * @param user The address of the user.
     * @param amount The amount of tokens unstaked.
     * @param stakeID The ID of the stake.
     */
    event TokensUnstaked(address indexed user, uint256 amount, uint256 stakeID);

    /**
     * @dev Event emitted when the admin adds rewards to the pool.
     * @param amount The amount of tokens added to the reward pool.
     */
    event RewardsAdded(uint256 amount);

    /**
     * @dev Constructor to initialize the staking contract with the token address.
     * @param _token The address of the ERC20 token to be staked.
     */
    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    /**
     * @notice Initializes the user's staking profile.
     */
    function initializeUser() external {
        require(
            !userStakeData[msg.sender][0].initialized,
            "User already initialized"
        );

        // User memory user;
        // user.userAddress = msg.sender;
        // user.stakeAmount = 0;
        // user.timeStamp = 0;
        // user.stakeID = 0;
        // user.initialized = true;

        userStakeData[msg.sender][0] = User({
            userAddress: msg.sender,
            initialized: true,
            stakeID: 0,
            stakeAmount: 0,
            timeStamp: 0
        });
        emit UserInitialized(msg.sender);
    }

    /**
     * @notice Allows a user to stake tokens.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint256 _amount) external payable {
        require(
            userStakeData[msg.sender][0].initialized,
            "User not initialized"
        );
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        uint8 stakeID = userStakeCount[msg.sender] + 1;
        // userStakeCount[msg.sender]++;
        // User memory user;
        // user.stakeAmount = _amount;
        // user.userAddress = msg.sender;
        // user.timeStamp = block.timestamp;
        // user.stakeID = stakeID;
        // user.initialized = true;

        userStakeData[msg.sender][stakeID] = User({
            stakeAmount: _amount,
            userAddress: msg.sender,
            timeStamp: block.timestamp,
            stakeID: stakeID,
            initialized: true
        });

        // optimized
        // userStakeCount[msg.sender]++;
        totalStaked += _amount;

        emit TokensStaked(msg.sender, _amount, stakeID);
    }

    /**
     * @notice Allows a user to unstake tokens after the lockup period.
     * @param _stakeID The ID of the stake to unstake.
     */
    function unstake(uint256 _stakeID) external {
        User memory user = userStakeData[msg.sender][_stakeID];
        require(user.initialized, "User not Initialized");

        require(
            block.timestamp >= user.timeStamp + LOCKUP_PERIOD,
            "Lockup period not completed"
        );

        totalStaked -= user.stakeAmount;
        if (rewardPool >= REWARD_AMOUNT) {
            user.stakeAmount += REWARD_AMOUNT;
            token.transfer(msg.sender, user.stakeAmount);
            rewardPool -= REWARD_AMOUNT;
        }

        emit TokensUnstaked(msg.sender, user.stakeAmount, _stakeID);

        // delete userStakeData[msg.sender][_stakeID];
    }

    /**
     * @notice Adds rewards to the reward pool. Only callable by the admin.
     * @param _amount The amount of tokens to add to the reward pool.
     */
    function addReward(uint256 _amount) external onlyOwner {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );
        require(_amount == 100 ether, "Amount must be 100 ether");
        rewardPool += _amount;

        emit RewardsAdded(_amount);
    }
}
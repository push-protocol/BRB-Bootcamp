// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BRBStaking is Ownable {
    IERC20 public token;
    uint256 public rewardRate = 100; // Reward rate per user

    struct Stake {
        address user;
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake[]) public userStakes;
    mapping(address => bool) public isInitialized;

    event Stake(address indexed user, uint256 indexed stakeId, uint256 amount);
    event Unstake(address indexed user, uint256 indexed stakeId, uint256 amount, uint256 reward);
    event RewardAdded(uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function initializeUser() external {
        require(!isInitialized[msg.sender], "User already initialized");
        isInitialized[msg.sender] = true;
    }

    function stake(uint256 _amount) external {
        require(isInitialized[msg.sender], "User not initialized");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        userStakes[msg.sender].push(Stake({
            user: msg.sender,
            amount: _amount,
            startTime: block.timestamp
        }));

        emit Stake(msg.sender, userStakes[msg.sender].length - 1, _amount);
    }

    function unstake(uint256 _stakeId) external {
        require(isInitialized[msg.sender], "User not initialized");
        Stake storage stake = userStakes[msg.sender][_stakeId];
        require(block.timestamp >= stake.startTime + 7 days, "Cannot unstake before 7 days");

        uint256 reward = rewardRate * stake.amount / 100;
        uint256 totalAmount = stake.amount + reward;

        require(token.transfer(msg.sender, totalAmount), "Transfer failed");

        emit Unstake(msg.sender, _stakeId, stake.amount, reward);

        delete userStakes[msg.sender][_stakeId];
    }

    function addReward(uint256 _amount) external onlyOwner {
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit RewardAdded(_amount);
    }
}

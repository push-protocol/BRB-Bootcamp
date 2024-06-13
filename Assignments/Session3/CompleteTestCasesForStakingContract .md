# Complete Test Cases for Staking Contract in Foundry

## Description

Your task is to enhance the test coverage of our staking contract by writing additional test cases in Foundry. The following specific tests need to be added:

- **Test Case file for reference:** [BRBStaking.t.sol](https://github.com/push-protocol/BRB-Bootcamp/blob/main/Assignments/Session3/BRB_Staking_Contract/test/BRBStaking.t.sol)

### Required Test Cases:

1. **Test for addReward() Function:**
   - Ensure the function works as expected.

2. **Ownership Checks:**
   - Only the owner should be able to call the addReward() function.

3. **Uninitialized User Restrictions:**
   - Ensure that an uninitialized user cannot stake or unstake tokens.

4. **Reward Distribution:**
   - Verify that the reward is exactly 100 tokens for all stakers.

5. **Unstake Restrictions:**
   - Ensure that if a staker tries to unstake before 7 days, the transaction should revert.

6. **Event Emissions:**
   - Accurately test the emission of Stake, Unstake, and RewardAdded events.

## Submission Instructions

1. **Create a Test File:**
   - Create a `.t.sol` file containing the entire code along with the newly added test cases.
   - Ensure your test cases are well-documented and follow best coding practices.

2. **Submission Requirements:**
   1. Clone the repository locally.
   2. Create a branch with the name format `YOUR_NAME_TASKNAME`.
   3. Look for a folder with your name in the Bootcampers folder.
   4. Create a folder and name it as per the task name.
   5. Add your `.t.sol` file in the folder.
   6. Raise a pull request (PR).

Your submission will be verified and merged!

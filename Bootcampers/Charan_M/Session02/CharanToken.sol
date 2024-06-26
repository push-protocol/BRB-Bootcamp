// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary OpenZeppelin contracts for ERC20 functionality, burning, ownership, and permit.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
   @title CharanToken - An ERC20 token example
   @author Charan 
   @custom:security-contact charanmadhu@yandex.com
*/
contract CharanToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    /**  @notice Constructor initializes the token contract
         @dev Sets the token name, symbol, initial owner, and mints initial supply to deployer
         @param initialOwner Address of the initial owner of the contract 
    */
    constructor(address initialOwner)
        ERC20("CharanToken", "CTK") // Token name: CharanToken, Symbol: CTK
        Ownable(initialOwner) // Set initial owner of the contract
        ERC20Permit("CharanToken") // Initialize ERC20Permit for gas-efficient approvals
    {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1 million tokens to the deployer
    }

    /** @notice Allows the owner to mint new tokens
        @dev Only callable by the owner of the contract
        @param to Address to receive the minted tokens
        @param amount Amount of tokens to mint
    */ 
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount); 
    }
}
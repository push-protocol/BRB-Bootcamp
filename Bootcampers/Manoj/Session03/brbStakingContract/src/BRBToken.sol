// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BRBToken is ERC20 {
    constructor(address initialOwner)
        ERC20("BRBToken", "BRB")
    {
        _mint(initialOwner  , 10000 ether);

    }
}

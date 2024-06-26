// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract sayantoken is ERC20 {
    constructor(uint256 initialSupply) ERC20("sayantoken","ST"){
        _mint(msg.sender,initialSupply);
    }
}
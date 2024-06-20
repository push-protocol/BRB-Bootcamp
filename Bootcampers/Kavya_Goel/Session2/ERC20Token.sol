pragma solidity ^0.8.19;

import "@openzepplin/contrats@5.0.2/token/ERC20/ERC20.sol" ;

contract KaviToken is ERC20 {
    constructur() ERC20("KaviToken", "KNT") {
         _mint(msg.sender, 10000 * 10 ** decinals());
    }
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

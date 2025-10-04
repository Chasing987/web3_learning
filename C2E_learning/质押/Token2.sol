// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token2 is ERC20{
    constructor(uint initalSupply) ERC20("Gold2", "GLD2"){
        _mint(msg.sender, initalSupply);
    }

    function mint(address to, uint256 amount) public{
        _mint(to, amount);
    } 
}
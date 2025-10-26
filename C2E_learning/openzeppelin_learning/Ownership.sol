// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable{
    constructor(address initialOwner) Ownable(initialOwner){

    }

    function normalThing() external {
        // anyone can call this normalThing()
    }

    function specialThing() external onlyOwner{
        // only the owner can call specialThing
    }

}
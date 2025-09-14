// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

contract Coin{
    address public minter;
    mapping (address=>uint) public  balances;
    event Sent(address from, address to, uint amout);
    constructor() {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[receiver] -= amount;
        balances[receiver] += amount;

        emit Sent(msg.sender, receiver, amount);
    }
}
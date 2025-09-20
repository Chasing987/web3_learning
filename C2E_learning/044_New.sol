// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Account{
    address public owner;
    address public bank;

    constructor(address _owner) payable {
        owner = _owner;
        bank = msg.sender;
    }
}

// 0xb7bb1792BBfabbA361c46DC5860940e0E1bFb4b9
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

contract AccountFactory{
    Account[] public accounts;

    function createAccount(address owner) external payable {
        require(msg.value >= 123, "Not enough ether sent");
        Account account = new Account{value:123}(owner);

        accounts.push(account);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
A calls B, sends 100 wei
B calls C, sends 50 wei

A ---> B ---> C
msg.sender = B
msg.value = 50
execute code on C's state variable
use eth in C
A calls B, sends 100 wei
B delegatecall C
A ---> B ---> C
msg.sender = A
msg.value = 100
execute code on B's state variable
use eth in B
*/

// NOTE: Deployee this contract first
contract B {
    // NOTE：storage layout must be the same as contract A
    uint256 public num;
    address public sender;
    uint256 public value;
    address public owner;

    function setVars(uint256 _num) public payable {
        num = 2 * _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(address _contract, uint256 _num) public payable {
        // A's storage is set, B is not modified.
        // _contract.delegatecall(
        // abi.encodeWithSignature("setVars(uint256)", _num)
        // );
        (bool success, ) = _contract.delegatecall(abi.encodeWithSelector(B.setVars.selector, _num));
        require(success, "delegatecall failed");
    }
}

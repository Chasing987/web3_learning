// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CounterV1{
    address public implementation;
    address public admin;
    uint256 public count;

    function increment() public {
        count += 1;
    }
}

contract CounterV2{
    address public implementation;
    address public admin;
    uint256 public count;

    function increment() public {
        count += 1;
    }

    function decrement() public {
        count -= 1;
    }
}

contract BuggyProxy{
    address public implementation;
    address public admin;

    constructor(){
        admin = msg.sender;
    }

    function upgradeTo(address _implementation) external {
        require(msg.sender == admin, "Not authorized");
        implementation = _implementation;
    }

    function _delegatecall()private {
        (bool success, ) = implementation.delegatecall(msg.data);
        require(success, "Delegate call failed");
    }

    fallback() external payable {
        _delegatecall();
    }

    receive() external payable {
        // _delegatecall();
    }
}
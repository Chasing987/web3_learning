// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

contract Callee{
    function setNum(uint _num) public {
        // this function will be called using delegateCall
    }
}

contract Caller{
    uint public num;

    function updateNum(address _callee, uint _num) public {
        (bool success, ) = _callee.delegatecall(
            abi.encodeWithSignature("setNum(uint256)", _num)
        );
        require(success, "delegatecall failed");
    }
}
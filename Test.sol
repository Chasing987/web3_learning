// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test{
    uint public a;
    uint[] public data;
    function f() public {
        uint[] x = data;
        x.push(2);
    }

}
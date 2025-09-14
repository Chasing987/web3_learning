// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint myData;

function setData(uint newData) public {
    myData = newData;
}

function getData() public  view returns (uint) {
    return myData;
}
}
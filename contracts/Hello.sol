// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello{
    string private message;

    // 够构造函数，接受一个字符串作为初始化信息
    constructor(string memory _initMessage){
        message = _initMessage;
    }

    function getMessage() public view returns ( string memory ){
        return message;
    }

    function setMessage(string memory _newMessage) public {
        message = _newMessage;
    }
}
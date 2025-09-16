// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendEther {
    event Log(uint amount, uint gas);

    // 接收以太
    receive() external payable { }

    // 使用transfer发送以太
    function sendByTransfer(address payable _to, uint _amount) public{
        _to.transfer(_amount);
    }

    // 使用send发送ETH
    function sendBySend(address payable _to, uint _amount) public returns (bool){
        bool sent = _to.send(_amount);
        require(sent, "Send failed");
        return sent;
    }

    // 使用call发送ETH
    function sendByCall(address payable  _to, uint _amount) public returns (bool){
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Call failed");
        return success;
    }
}
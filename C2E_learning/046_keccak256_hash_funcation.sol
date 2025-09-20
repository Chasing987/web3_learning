// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Alice：
计算消息的哈希值：hash(message) = H
用她的私钥对哈希值进行签名：signature = Sign(H, Alice's private key)
发送消息和签名给 Bob
Bob：
接收到消息和签名
用 Alice 的公钥对签名进行验证，得到哈希值：H' = Verify(signature, Alice's public
key)
计算接收到消息的哈希值：H'' = hash(message)
比较 H' 和 H''，如果相等，消息未被篡改且确实来自 Alice
*/

contract HashFunc{
    function hash(string memory text, uint num, address addr) external pure returns(bytes32){
        return keccak256(abi.encodePacked(text, num, addr));
      
    }

    function encode(string memory text0, string memory text1) external pure returns (bytes memory){
        return abi.encode(text0, text1);
    }

    function encodePacked(string memory text0, string memory text1) external pure returns (bytes memory){
        return abi.encodePacked(text0, text1);
    }
}

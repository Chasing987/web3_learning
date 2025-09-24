// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
- 功能：一个简单的目标，构造函数接收一个owner地址并存储
*/
contract DeployWithCreate2{
    address public owner;

    constructor(address _owner){
        owner = _owner;
    }
}

/*
- 功能：一个工厂合约，允许你通过CREATE2 和 一个salt来部署DeployWithCreate2, 并提供一些方法
*/
contract Create2Factory{
    event Deploy(address addr); // 部署事件

    // 功能：通过CREATE2方式部署了一个新的DeployWithCreate2 合约，并将当前调用者msg.sender作为构造函数的_owner参数传入
    function deploy(uint _salt) external {
        DeployWithCreate2 _contract = new DeployWithCreate2{
            salt: bytes32(_salt)
        }(msg.sender);

        emit Deploy(address(_contract));
    }

    // 功能：根据CREATE2的地址计算公式，估算一个合约将来被CREATE2部署时的地址
    function getAddress(bytes memory byteCode, uint _salt) public view returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(byteCode)
            )
        );

        // 20/32 = 0.625
        // 160/256 = 0.625
        return address(uint160(uint256(hash)));
    }

    // 功能：返回目标合约DeployWithCreate2的完整部署字节码
    function getBytecode(address _owner) public pure returns (bytes memory){
        bytes memory bytecode = type(DeployWithCreate2).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }
}
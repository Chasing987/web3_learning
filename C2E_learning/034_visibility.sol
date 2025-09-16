// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// visibility
// private - 只在合约内部
// internal - 合约内部或子合约
// public - 内部或外部
// external - 只能外部调用
/*
A
private pri()
internal inter()
public pub() <-------- C pub() and ext()
external ext()
B is A
inter() <-------- C pub() and ext()
pub()
*/

contract Base {
    uint private x = 0;
    uint internal y = 1;
    uint public z = 2;
    function privateFunc() private pure returns (uint) {
        return 0;
    }
    function internalFunc() internal pure returns (uint) {
        return 100;
    }
    function publicFunc() public pure returns (uint) {
        return 200;
    }
    function externalFunc() external pure returns (uint) {
        return 300;
    }
    function examples() external view {
        x + y + z;
        privateFunc();
        internalFunc();
        publicFunc();
    }
}

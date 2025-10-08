// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Factory{
    event Log(address addr);

    function deploy() external {
        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";
        address addr;
        assembly{
            addr := create(0, add(bytecode, 0x20), 0x13)
        }

        require(addr != address(0), "deploy failed");

        emit Log(addr);
    }
}

interface IContract {
    function getMeaningOfLife() external view returns (uint);
}

/*
return(p, s) - end execution and return data from memory p to p + s
mstore(p, v) - store v at memory p to p + 32

PUSH1 0x2a
PUSH1 0
MSTORE

Return 32 bytes from memory
PUSH1 0x20
PUSH1 0
RETURN

https://www.evm.codes/playground
Run time code - return 42
602a60005260206000f3

Creation code
Store run time code to memory

PUSH10 0x602a60005260206000f3
PUSH1 0
MSTORE

0x00000000000000000000000000000000000000000000602a60005260206000f3

Return 10 bytes from memroy starting at offset 22

PUSH1 0x0a
PUSH1 0x16
RETURN

69602a60005260206000f3600052600a6016f3
*/


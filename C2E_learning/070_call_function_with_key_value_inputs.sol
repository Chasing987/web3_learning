// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract XYZ {
    function someFuncWithManyInputs(
        uint x,
        uint y,
        uint z,
        address a,
        address b,
        string memory c
    ) public pure returns (uint) {}

    function callFunc() external pure  returns (uint){
        return someFuncWithManyInputs(1, 2, 3, address(0), address(0), "c");
    }

    function callFuncWithKeyValue() external pure returns (uint){
        return someFuncWithManyInputs({
            x: 1,
            y: 2,
            z: 3,
            a: address(0),
            b: address(0),
            c : "c"
        });
    }
}

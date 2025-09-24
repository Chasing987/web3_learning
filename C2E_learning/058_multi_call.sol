// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestMultiCall{
    function func1() external  view returns (uint, uint){
        return(1, block.timestamp);
    }

    function func2() external view returns (uint, uint){
        return(2, block.timestamp);
    }

    // 作用：将一个4字节的函数选择器（selector）和若干参数，按照ABI规则一起编写一串bytes(即calldata)
    function getData1() external pure returns (bytes memory){
        // return abi.encodeWithSignature("func1()");
        return abi.encodeWithSelector(this.func1.selector);
    }

    function getData2() external pure returns (bytes memory){
        // return abi.encodeWithSignature("func2()");
        return abi.encodeWithSelector(this.func2.selector);
    }
}

contract MultiCall{
    function multiCall(address[] calldata targets, bytes[] calldata data) external view returns (bytes[] memory){
        require(targets.length == data.length, "target lenth != data length");
        bytes[] memory results = new bytes[](data.length);

        for(uint i; i < targets.length; i++){
            (bool success, bytes memory result) = targets[i].staticcall(data[i]); // 发起只读调用
            require(success, "tx failed");
            results[i] = result;
        }

        return results;
    }
}
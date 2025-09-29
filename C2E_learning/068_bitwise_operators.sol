// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BitwiseOps{
    function and(uint256 x, uint256 y) external pure returns (uint256){
        return x & y;
    }

    function or(uint256 x, uint256 y) external pure returns (uint256){
        return x | y;
    }

    function xor(uint256 x, uint256 y) external pure returns (uint256){
        return x ^ y;
    }

    function not(uint8 x) external pure returns (uint8){
        return ~x;
    }

    function shiftLeft(uint256 x, uint256 bits) external pure returns (uint256){
        return x << bits;
    }

    function rightLeft(uint256 x, uint256 bits) external pure returns (uint256){
        return x >> bits;
    }

    function getLastNBits(uint256 x, uint256 n) external  pure returns (uint256){
        uint mask = (1 << n) - 1;
        return x & mask;
    }

    function getLastNBitUsingMod(uint x, uint n) external pure returns (uint256){
        return x % (1 << n);
    }
}
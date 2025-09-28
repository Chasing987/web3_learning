// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasGolf{
    // start - 55167 gas
    // use calldata - 54438 gas
    // load state variables to memory - 54187 gas
    // short circuit - 53815 gas
    // loop increments - 53304 gas
    // cache array length - deprecated
    // load array elements to memory - 53097 gas

    /*
    燃气优化技巧
    • 使用calldata代替memory：通过改变变量存储位置来减少燃气消耗。
    • 循环内部变量优化：在循环开始前将状态变量加载到内存，循环结束后再更新状态变量。
    • 表达式短路（Short Circuiting）：优化条件判断逻辑，避免不必要的计算。
    • 循环增量简化：使用 ++i 代替 i + 1 来减少操作。
    • 缓存数组长度：将数组长度存储在局部变量中，减少每次循环的计算量。
    • 数组元素加载到内存：将频繁访问的数组元素预先加载到变量中。
    */

    uint256 public total;

    function sumIfEventAndLessThan99(uint[] calldata nums) external {
        uint _total = total;
        for (uint i = 0; i < nums.length; ++i){
            uint num = nums[i];
            if(num % 2 == 0 && num < 99){
                _total += num;
            }
        }
        total = _total;
    }
}
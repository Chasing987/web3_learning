// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256); // 返回该代币的总供应量是多少
    function balanceOf(address account) external view returns (uint256); // 返回某个地址拥有多少代币
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool); // 从调用者地址转账指定数量的代币到recipient地址
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256); // 返回spender被允许从owner地址花费的代币数量
    function approve(address spender, uint256 amount) external returns (bool); // 允许spender地址从你的账户转出amount数量的代币
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool); // 从sender地址转账amount到recipient，前提是已经通过approve授权
}

contract ERC20 is IERC20 {
    uint public totalSupply; // 该代币的总发行量
    mapping(address => uint256) public balanceOf; // 记录每个地址拥有多少代币

    mapping(address => mapping(address => uint)) public allowance; // 记录某地址（owner）允许另一个地址（spender）使用多少代币

    string public name = "Test"; // 代币名称
    string public symbol = "Test"; // 代币符号
    uint8 public decimals = 18; // 代币精度（通常为18）

    event Transfer(address indexed from, address indexed to, uint256 value); // 当代币转账时触发（包括初始mint或者销毁时从0地址转出）
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    ); // 当某个地址授权另一个地址使用其代币时

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

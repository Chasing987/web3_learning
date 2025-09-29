// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 引入 OpenZeppelin 提供的标准 ERC20 Token 合约实现，这是一个经过审计、安全的库。
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
- 作用：将原生ETH(即“非代币化”的以太币)包装成符合ERC20标准的代币，从而可以在那些只接受ERC20代币的Defi协议中使用
*/

contract WETH is ERC20 {
    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);

    /*
    - 在调用父类（也就是OpenZeppelin的ERC20合约）的构造函数，并传入两个参数：代币的名称（name） 和 符号（symbol）
    */
    constructor() ERC20("Wrapped Ether", "WETH") {}

    /*
    - 接收ETH的备用入口
    - 当有人向该合约发送ETH但是没有调用任何函数（比如直接通过send或者某些未严格匹配函数签名的交易），就会触发fallback函数
    - 这样无论是通过普通转账（无函数调用）还是通过调用未定义函数，都会触发存款逻辑
    */
    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    /*
    - 允许用户存入ETH，并且获得等值的WETH代币
    - _mint(msg.sender, msg.value)：给发送者（msg.sender）铸造 msg.value（即转入的 ETH 数量，单位是 wei）对应的 WETH 
    - 比如，用户转入 1 ETH (= 1e18 wei)，则会铸造 1e18 个 WETH。
    - 触发 Deposit事件，便于链上监控和前端展示。
    */
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /*
    - 功能：将 WETH 兑换回 ETH
    - 参数：_amount是用户希望兑换的 WETH 数量（单位是 ​​代币的最小单位，通常是 wei 级别​​，和 ERC20 一致）。
    - 逻辑：
        _burn(msg.sender, _amount)：销毁调用者账户下的 _amount枚 WETH 代币。
        payable(msg.sender).transfer(_amount)：将 _amount数量的 ​​原生 ETH​​ 发送回用户。
    */
    function withdraw(uint _amount) external {
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }
}

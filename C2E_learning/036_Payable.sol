// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PayableExample {
    address payable public immutable owner;  // immutable 节省 gas
    uint256 public depositCount;            // 添加统计指标

    // 事件：透明化资金流动
    event EtherReceived(address indexed sender, uint256 amount, uint256 totalBalance);
    event EtherWithdrawn(address indexed recipient, uint256 amount, uint256 remainingBalance);

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev 接收 ETH 的默认函数（替代 receiveEther）
     * @notice 发射 EtherReceived 事件，统计存款次数
     */
    receive() external payable {
        depositCount++;
        emit EtherReceived(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @dev 显式存款函数（与 receive() 功能重叠，可选保留）
     * @notice 保留以兼容旧接口，但建议迁移到 `receive()`
     */
    function deposit() external payable {
        depositCount++;
        emit EtherReceived(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @dev 提款函数（仅限 owner）
     * @param amount 提款金额
     * @param recipient 接收地址（默认为 owner）
     */
    function withdraw(uint256 amount, address payable recipient) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(address(this).balance >= amount, "Insufficient balance");

        uint256 remainingBalance = address(this).balance - amount;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit EtherWithdrawn(recipient, amount, remainingBalance);
    }

    /**
     * @dev 查询合约余额
     * @return 合约当前 ETH 余额
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 查询存款次数
     * @return 累计存款次数
     */
    function getDepositCount() external view returns (uint256) {
        return depositCount;
    }
}
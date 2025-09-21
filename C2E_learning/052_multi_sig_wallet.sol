// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet{
    event Deposit(address indexed sender, uint amount); // ETH存款事件
    event Submit(uint indexed txId); // 交易提交事件
    event Approve(address indexed owner, uint indexed txId); // 交易批准事件
    event Revoke(address indexed owner, uint indexed txId); // 批准撤销事件
    event Execute(uint indexed txId); // 交易执行事件

    struct Transaction{
        address to; // 目标地址
        uint value; // 转账金额（wei）
        bytes data; // 调用数据
        bool executed; // 是否已经执行
    }

    address[] public owners; // 所有者地址列表
    mapping(address => bool) public isOwner; // 地址到所有者状态的映射
    uint public required; // 交易计数，执行交易所需的最小确认数

    Transaction[] public transactions; // 交易列表
    mapping (uint => mapping (address => bool)) public approved; // 交易ID到批准者的映射

    // 仅所有者可调用
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // 交易必须存在
    modifier txExists(uint _txId){
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    // 调用者尚未批准该交易
    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    // 交易尚未执行
    modifier notExecuted(uint _txId){
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    /*
    - 构造函数
    - 至少需要1个所有者
    - 所有者确认数必须在1到所有者数量之间
    - 所有者地址不能为零地址
    - 所有者地址必须唯一
    */ 
    constructor(address[] memory _owners, uint _required){
        require(_owners.length > 0, "owners require");
        require(
            _required > 0 && _required <= owners.length, "invalid required number"
        );

        for (uint i = 0; i < _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    // 存款功能  允许接收以太，触发Deposit事件记录存款
    receive() external payable { 
        emit Deposit(msg.sender, msg.value);
    }

    // 提交交易 只有所有者可以提交交易，创建新交易并添加至列表，返回交易ID
    function submit(address _to, uint _value, bytes calldata _data) external  onlyOwner{
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }
    
    /*
    - 批准交易
    - 满足是所有者、交易存在、还未被批准、未被执行的条件
    - 记录批准状态
    - 触发批准事件
    */
    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    /*
    - 遍历所有者计算当前批准数
    - 返回达到的批准数量
    */
    function _getApprovalCount(uint _txId) private view returns (uint count){
        for(uint i = 0; i < owners.length; i ++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    /*
    - 执行交易
    - 检查批准数是否已经达标
    - 标记交易为已执行
    - 执行外部调用
    - 验证调用结果
    - 触发执行事件
    */
    function execute(uint _txId) external txExists(_txId) notExecuted(_txId){
        require(_getApprovalCount(_txId) > required, "approvals < required");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");
        emit Execute(_txId);
    }

    /*
    - 撤销批准
    - 运行所有者在执行前撤销批准
    - 更新批准状态
    - 触发撤销事件
    */
    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

}

// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
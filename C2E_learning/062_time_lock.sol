// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
- ​​queue(...)​​：将一笔交易请求“排队”，但不会立即执行。该交易将在指定的未来时间戳 _timestamp才能被执行。
​- ​execute(...)​​：在满足时间条件后，执行之前排队的交易。
- ​​cancel(...)​​：取消一个已经排队但尚未执行的交易。
- 使用了一系列的 ​​error​​ 和 ​​event​​ 来精确控制流程和提供调用信息。
*/

contract TimeLock{
    error NotOwnerError();
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint blockTimestamp, uint timestamp);
    error TimestampExpiredError(uint blockTimestamp, uint expiredAt);
    error TxFailedError();

    event Queue(bytes32 indexed txId, address indexed target, uint value, string func, bytes data, uint timestamp);
    event Execute(bytes32 indexed txId, address indexed target, uint value, string func, bytes data, uint timestamp);
    event Cancel(bytes32 indexed txId);

    uint public constant MIN_DELAY = 10; // 最小延迟：10 秒
    uint public constant MAX_DELAY = 1000; // 最大延迟：1000 秒 (~16分钟)
    uint public constant GRACE_PERIOD = 100; // 生效窗口期：执行必须在 _timestamp ~ _timestamp + 100 秒内

    address public owner; // 合约所有者
    mapping(bytes32 => bool) public queued; // 通过一个 mapping 来记录哪些交易已经被“排队”。

    constructor(){
        owner = msg.sender;
    }

    receive() external payable {}
    modifier onlyOwner(){
        if(msg.sender != owner){
            revert NotOwnerError();
        }
        _;
    }

    /*
    - 通过 keccak256对以下参数进行哈希，生成唯一交易 ID
    - 目标合约地址 _target
    - 转账金额 _value
    - 函数名称字符串 _func
    - 调用数据 _data
    - 执行时间戳 _timestamp
    - 这个 ID 用于唯一标识一笔排队的交易，防止重复排队或错误执行。
    */
    function getTxId(address _target, uint _value, string calldata _func, bytes calldata _data, uint _timestamp) public pure returns (bytes32 txId){
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }

    /*
    - 作用：​​ 将一个调用请求加入队列，但并不执行。
    ​​参数：​​
    _target: 目标合约地址
    _value: 转账的 ETH 数量（wei）
    _func: 要调用的函数名（字符串）
    _data: 调用数据（通常为函数签名 + 参数编码）
    _timestamp: 希望执行的时间戳
    */
    function queue(address _target, uint _value, string calldata _func, bytes calldata _data, uint _timestamp)external onlyOwner{
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        if(queued[txId]){
            revert AlreadyQueuedError(txId);
        }

        if(_timestamp < block.timestamp + MIN_DELAY || _timestamp > block.timestamp + MAX_DELAY){
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        // queue tx
        queued[txId] = true;
        emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }

    /*
    - 作用：​​ 在满足时间条件时，执行之前排队的交易。
    */
    function execute(address _target, uint _value, string calldata _func, bytes calldata _data, uint _timestamp) external payable onlyOwner returns (bytes memory){
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);

        // check tx is queued
        if(!queued[txId]){
            revert NotQueuedError(txId);
        }

        // check block.timestamp > _timestamp
        if(block.timestamp < _timestamp){
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }

        if(block.timestamp > _timestamp + GRACE_PERIOD){
            revert TimestampExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
        }

        queued[txId] = false;
        bytes memory data;
        if(bytes(_func).length > 0){
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
        }else{
            data = _data;
        }

        // execute the tx
        (bool success, bytes memory returnData) = _target.call{value: _value}(data);
        if(!success){
            revert TxFailedError();
        }
        emit Execute(txId, _target, _value, _func, _data, _timestamp);
        return returnData;
    }

    function cancel(bytes32 _txId) external onlyOwner{
        if(!queued[_txId]){
            revert NotQueuedError(_txId);
        }
        queued[_txId] = false;
        emit Cancel(_txId);
    }
}

contract TestTimeLock{
    address public timeLock;

    constructor(address _timeLock){
        timeLock = _timeLock;
    }

    function test() external view {
        require(msg.sender == timeLock);

        // more code such as
        // 升级合约
        // 转移资产
        // 修改预言机
    }

    function getTimestamp() external view returns (uint){
        return block.timestamp + 100;
    }
}
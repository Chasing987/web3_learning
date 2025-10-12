// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
1. 重现透明可升级代理，并探讨其错误实现。
2. 视频系列内容：
    - 错误实现可升级代理合约,分析错误实现中的问题
    - 返回回退函数中的数据 fallback
    - 在智能合约的存储槽中写⼊任意数据
    - 存储实现合约地址和admin地址
    - 分离admin和user接⼝
    - proxy admin合约
    - 实际操作演⽰
*/

/*
一个典型的升级流程如下：
1、部署 CounterV1（逻辑合约 V1）
2、部署 Proxy，其初始化时设置 implementation 为 CounterV1 地址
3、用户通过 Proxy 调用 increment()，实际调用的是 CounterV1 的逻辑
4、部署 CounterV2（逻辑合约 V2，新增了 decrement()）
5、通过 ProxyAdmin或直接（如果是管理员）调用 Proxy.upgradeTo(CounterV2地址)
6、之后通过 Proxy 调用 decrement()就会成功
*/

// 逻辑合约v1：包含业务逻辑的合约版本，但是不存储数据
contract CounterV1{
    uint256 public count;

    function increment() public {
        count += 1;
    }

    function admin() external pure returns (address){
        return address(1);
    }

    function implementation() external pure returns (address){
        return address(2);
    }
}

// 逻辑合约v2：包含业务逻辑的合约版本
contract CounterV2{
    uint256 public count;

    function increment() public {
        count += 1;
    }

    function decrement() public {
        count -= 1;
    }
}

// 代理合约：将调用委托给逻辑合约，支持升级逻辑合约和管理员
// 代理合约：负责存储所有数据，并将函数调用委托（delegatecall）给另一个逻辑合约（Implementation）
// 当我们想要升级合约，只需要更改代理指向的逻辑合约地址，而无需迁移数据
contract Proxy{

    /*
    - 在Solidity智能合约中，所有的状态变量都会被存储在区块链的存储空间中，这个存储是一个巨大的键值存储。
    - 编译器会自动为变量分配一个存储槽（storage slot）编号，比如第0号槽，然后将变量admin的值存储在那里。
    - 但是对于代理合约（proxy contract）来说，它本身并不实现业务逻辑，而是通过delegatecall把调用转发给另一个逻辑合约（Implementation contract），
      同时它自己需要保存两个关键信息：
      1、当前使用的逻辑合约地址（即implementation地址）
      2、谁有权管理这个代理（即admin地址）
    - 如果我们直接将这些信息定义为状态变量，那么问题来了，如果逻辑合约也定义了自己的storage变量，会与代理的storage发生冲突，
      因为delegatecall的特点是：代码在逻辑合约中执行，但读取 和 写入的存储，是代理合约的存储！
      如果逻辑合约和代理合约都定义了相同位置（比如slot 0）的state variables，就会发生意外的覆盖，这样就会导致数据混乱，代理失效，资金被盗等严重问题
    - 为了避免这种问题，需要使用固定的，与用户合约不冲突的存储插槽位置，让代理合约中的关键变量（如implementation 和 admin）存储一些特殊、约定好、且不会与用户业务合约冲突的位置。
    - 这也是EIP-1967的由来
    - IMPLEMENTATION_SLOT 和 ADMIN_SLOT 是定义了两个特殊位置的存储插槽位置（bytes32类型），用于安全地存储。
    - 为什么这样做是必要且安全的？
        - 避免冲突：
          - 通过使用EIP-1967定义的标准槽，可以保证这些关键变量（admin和implementation）不会与用户业务逻辑合约中的任何state variables冲突；
          - 因为业务合约中的变量是从slot 0开始依次分配的，而EIP-1967的插槽是经过哈希的，几乎不可能与业务变量重合。
        - 标准化 & 通用性：
          - 其他工具（例如OpenZeppelin、Hardhat、Tenderly、Remix插件等）都遵循EIP-1967，知道这些插槽位置存的是什么；
          - 如果大家都用统一标准，生态工具可以更容易识别、调试、升级、交互代理合约；
        - 安全最佳实践
          - 不使用固定的slot0、1、2等易冲突位置
          - 使用哈希+标准命名的方式，防止意外覆盖和冲突
    */ 

    // EIP-1967标准：定义了标准的存储插槽位置，以避免和用户合约冲突
    // IMPLEMENTATION_SLOT：当前逻辑合约的地址
    bytes32 public constant IMPLEMENTATION_SLOT = bytes32(uint(keccak256("eip1967.proxy.implementation")) - 1);

    // ADMIN_SLOT：当前代理的管理员地址
    bytes32 public constant ADMIN_SLOT = bytes32(uint(keccak256("eip1967.proxy.admin")) - 1);

    // 构造函数：初始化时，将部署者设置为管理员
    constructor(){
        // admin = msg.sender;
        _setAdmin(msg.sender);
    }

    /*
    - 使用汇编直接操作内存和调用
        - 将calldata复制到内存起始位置
        - 调用delegatecall到_implementation地址
        - 处理返回数据或异常（revert）
    */ 
    function _delegatecall(address _implementation)private {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            // calldatacopy(t, f, s) - copy s bytes from calldata at position f to mem at position t
            // calldatasize() - size of call data in bytes
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            // delegatecall(g, a, in, insize, out, outsize) -
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error (eg. out of gas) and 1 on success
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            // returndatacopy(t, f, s) - copy s bytes from returndata at position f to mem at position t
            // returndatasize() - size of the last returndata
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                // revert(p, s) - end execution, revert state changes, return data mem[p…(p+s))
                revert(0, returndatasize())
            }

            default {
                // return(p, s) - end execution, return data mem[p…(p+s))
                return(0, returndatasize())
            }
        }
    }

    /*
    - 当代理收到未处理的调用时，调用_delegatecall(_getImplementation())，即将调用委托给当前逻辑合约
    */ 
    function _fallback() private {
        _delegatecall(_getImplementation());
    }

    // 捕获所有未匹配的函数调用，将其委托给逻辑合约
    fallback() external payable {
        _fallback();
    }

    // 目前为空，但通常可用于接收ETH
    receive() external payable {
        // _delegatecall();
    }

    // 修饰符：只有管理才能进行下一步的操作，普通用户只能调用逻辑合约中的操作
    modifier ifAdmin(){
        if(msg.sender == _getAdmin()){
            _;
        }else{
            _fallback();
        }
    }

    // 更改管理员，但仅管理员可调用
    function changeAdmin(address _admin) external ifAdmin{
        _setAdmin(_admin);
    }

    // 升级逻辑合约，但仅管理员可调用
    function upgradeTo(address _implementation) external ifAdmin {
        _setImplementation(_implementation);
    }

    /*
    - 读取存储在ADMIN_SLOT 位置上定义的AddressSlot 结构体中的value字段，即管理员地址
    */
    function _getAdmin() private view returns (address){
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    function _setAdmin(address _admin) private{
        require(_admin != address(0), "admin = 0 address");
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = _admin;
    }

    /*
    - 读取存储在IMPLEMENTATION_SLOT 位置上定义的AddressSlot 结构体中的value字段，即管理员地址
    */
    function _getImplementation() private view returns (address){
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address _implementation) private {
        require(_implementation.code.length > 0, "not a contract");
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = _implementation;
    }

    function admin() external ifAdmin returns (address){
        return _getAdmin();
    } 
    
    function implementation() external ifAdmin  returns (address){
        return _getImplementation();
    }
}

/*
- 代理管理合约：提供更高层的接口来管理代理（如更改管理员、升级逻辑合约）
- 这是一个更高级的抽象，允许一个拥有权中心化管理者（owner）管理多个代理
- 功能：
    - getProxyAdmin/ getProxyImplementation：通过 staticcall 查询代理的管理员和实现合约地址
    - changeProxyAdmin：更改某个代理的管理员
    - upgrade：升级某个代理的逻辑合约

*/ 
contract ProxyAdmin{
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "not authorized");
        _;
    }

    function getProxyAdmin(address proxy) external view returns (address){
        (bool ok, bytes memory res) = proxy.staticcall(
            abi.encodeCall(Proxy.admin, ())
        );

        require(ok, "call failed");
        return abi.decode(res, (address));
    }

    function getProxyInplementation(address proxy) external view returns (address){
        (bool ok, bytes memory res) = proxy.staticcall(
            abi.encodeCall(Proxy.implementation, ())
        );
        require(ok, "call failed");
        return abi.decode(res, (address));
    }

    function changeProxyAdmin(address payable proxy, address _admin) external onlyOwner{
        Proxy(proxy).changeAdmin(_admin);
    }

    function upgrade(address payable proxy, address implementation) external onlyOwner{
        Proxy(proxy).upgradeTo(implementation);
    }
}

/*
- 存储槽工具：一个库，用于安全地读写合约存储中的特定插槽
- 利用Solidity的内联汇编，将一个bytes32类型的插槽变量绑定到合约存储的某个位置，从而可以直接读写该存储槽的值。
*/ 
library StorageSlot{
    struct AddressSlot{
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r){
        assembly{
            r.slot := slot
        }
    }
}

// 测试合约：用于测试存储槽读写功能
contract TestSlot{
    bytes32 public constant SLOT = keccak256("TEST_SLOT");

    function getSlot() external view returns (address){
        return StorageSlot.getAddressSlot(SLOT).value;
    }

     function writeSlot(address _addr) external {
        StorageSlot.getAddressSlot(SLOT).value = _addr;
     }
}
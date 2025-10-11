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

contract CounterV2{
    uint256 public count;

    function increment() public {
        count += 1;
    }

    function decrement() public {
        count -= 1;
    }
}

contract Proxy{

    bytes32 public constant IMPLEMENTATION_SLOT = bytes32(uint(keccak256("eip1967.proxy.implementation")) - 1);

    bytes32 public constant ADMIN_SLOT = bytes32(uint(keccak256("eip1967.proxy.admin")) - 1);

    constructor(){
        // admin = msg.sender;
        _setAdmin(msg.sender);
    }

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

    function _fallback() private {
        _delegatecall(_getImplementation());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        // _delegatecall();
    }

    modifier ifAdmin(){
        if(msg.sender == _getAdmin()){
            _;
        }else{
            _fallback();
        }
    }

    function upgradeTo(address _implementation) external ifAdmin {
        _setImplementation(_implementation);
    }

    function _getAdmin() private view returns (address){
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    function _setAdmin(address _admin) private{
        require(_admin != address(0), "admin = 0 address");
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = _admin;
    }

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

contract TestSlot{
    bytes32 public constant SLOT = keccak256("TEST_SLOT");

    function getSlot() external view returns (address){
        return StorageSlot.getAddressSlot(SLOT).value;
    }

     function writeSlot(address _addr) external {
        StorageSlot.getAddressSlot(SLOT).value = _addr;
     }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TPUProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address initialOwner,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, initialOwner, _data) {}

    receive() external payable {}

    function proxAdmin() external view returns (address) {
        return _proxyAdmin();
    }

    function getImplments() external view returns (address) {
        return _implementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract VerifySignature {
    using ECDSA for bytes32;

    using  MessageHashUtils for bytes32;

    function recover(string memory str, bytes memory signature) external pure returns (address){
        bytes32 hash = keccak256(bytes(str));

        return hash.toEthSignedMessageHash().recover(signature);
    }
    
} 
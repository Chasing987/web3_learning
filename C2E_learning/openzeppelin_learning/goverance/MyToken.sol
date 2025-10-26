// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
// import "@openzeppelin/contracts/utils/";
import "@openzeppelin/contracts/access/Ownable.sol";

// 暂时有点搞不定这个goverance这个合约
// contract MyToken is ERC20, ERC20Permit, ERC20Votes, Ownable{

//     function _update(address from, address to, uint256 amount) internal  {
//         super._update(from, to, amount);
//     }

//     function nonces(address owner) public view virtual  override returns (uint256){
//         return super.nonces(owner);
//     }
// }

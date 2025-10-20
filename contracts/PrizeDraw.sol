// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract PrizeDraw {
    event PrizeResult(uint prizeNumber, bool isWin);

    constructor() {

    }

    // 发起一次抽奖 随机数 0-9 >5 表示中奖，反之不中奖
    function start() public{
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.number))) % 10;

        if(randomNumber > 5){
            emit PrizeResult(randomNumber, true);
        }else {
            emit PrizeResult(randomNumber, false);
        }
    }
}
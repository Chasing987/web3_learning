// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定义了ERC721 接口，只包含了transferFrom函数，用于NFT的转移
interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId) external;
}

contract EnglishAuction{
    event Start(); // 拍卖开始事件
    event Bid(address indexed sender, uint amount); // 出价事件，记录出价者和出价金额
    event Withdraw(address indexed bidder, uint amount); // 提款事件，记录提款者和提款金额
    event End(address highestBidder, uint highestBid); // 拍卖结束事件，记录最高出价者和最终价格

    // NFT 相关信息
    IERC721 public immutable nft; // 被拍卖的NFT合约地址（不可变）
    uint public immutable nftId; // 被拍卖的NFT的ID（不可变）

    // 拍卖信息
    address payable public immutable seller; // 卖家地址（不可变，可支付）
    uint public endAt; // 拍卖结束时间戳
    bool public started; // 拍卖是否已经开始
    bool public ended; // 拍卖是否已经结束

    address public highestBidder; // 当前最高出价者
    uint public highestBid; // 当前最高出价
    mapping (address => uint) public bids; // 记录每个出价者的出价总额（用于退款）

    // 初始化 NFT合约地址、NFT ID 和 起拍价
    constructor(address _nft, uint _nftId, uint _startingBid){
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }
    
    /*
    - 卖家发起拍卖 
    - 只有卖家可以调用
    - 设置拍卖开始标志
    - 设置拍卖结束时间为60秒后
    - 将NFT转移到合约
    - 触发start事件
    */  
    function start() external {
        require(msg.sender == seller, "not seller");
        require(!started, "already started");
        
        started = true;
        endAt = uint32(block.timestamp + 60);
        nft.transferFrom(seller, address(this), nftId);

        emit Start();
    }

    /*
    - 卖家竞价
    - 拍卖必须已经开始且未结束
    - 如果已有最高出价者，将其之前的出价存入bids映射（用于退款）
    - 更新最高出价者和最高出价
    - 触发bid事件
    */ 
    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest bid");

        if(highestBidder != address(0)){
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
         emit Bid(msg.sender, msg.value);
    }

    /*
    - 买家提款
    - 允许出价者提取他们未成功的出价
    - 先检查并清零出价者的余额
    - 然后转账
    - 触发Withdraw事件
    */ 
    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable (msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    /*
    - 结束拍卖
    - 拍卖必须已开始且已到结束时间
    - 拍卖不能已结束
    - 如果有出价者，将NFT转移给最高出价者，将最高出价转账给卖家
    - 如果没有出价者，将NFT退还给卖家
     - 触发End事件
    */ 
    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not end");
        require(!ended, "ended");

        ended = true;
        if(highestBidder != address(0)){
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        }else{
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
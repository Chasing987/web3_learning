// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId)external;
}

contract DutchAuction{
    // NFT相关信息
    IERC721 public immutable nft;
    uint public immutable nftId;

    // 拍卖信息
    uint private constant DURATION = 7 days;
    address public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAt;
    uint public immutable expireAt;
    uint public immutable discountRate;

    // 卖家出售 NFT
    constructor(
        uint _startingPrice,
        uint _discountRate,
        address _nft,
        uint _nftId
    ){
        seller = payable (msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expireAt = block.timestamp + DURATION;

        require(_startingPrice >= _discountRate * DURATION, "starting price < discount");

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    // 买家购买 NFT
    function buy() external payable {
        require(block.timestamp < expireAt, "aution expired");

        uint price = getPrice();
        require(msg.value >= price, "ETH < priice");

        nft.transferFrom(seller, msg.sender, nftId);

        // 将拍卖款转给卖家
        (bool success, ) = payable (seller).call{value: price}("");
        require(success, "Failed to send ETH to Seller");

        // 退还多余的ETH给买家
        uint refund = msg.value - price;
        if(refund > 0){
            (bool success_refund, ) = payable (msg.sender).call{value: refund}("");
            require(success_refund, "Failed to refund");
        }
    }

    // 查看当前的价格
    function getPrice() public view returns(uint){
        uint timeElapsed = block.timestamp - startAt;
        uint discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }
}
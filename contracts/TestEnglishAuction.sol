// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../34_ERC721/ERC721.sol";

contract EnglishAuction is Ownable, ERC721 {
    uint256 public constant COLLECTION_SIZE = 10000; // NFT总数
    uint256 public auctionStartTime; // 拍卖开始时间戳
    uint256 public auctionEndTime; // 拍卖结束时间戳
    uint256 public highestBid; // 最高出价
    address public highestBidder; // 最高出价者
    uint256 public reservePrice; // 保留价，最低价格，拍卖必须超过这个价格才能成交
    bool public auctionEnded; // 拍卖是否结束
    string private _baseTokenURI; // metadata URI
    uint256[] private _allTokens; // 记录所有存在的tokenId

    mapping(address => uint256) public pendingReturns; // 记录所有出价者的可退还金额

    //设定拍卖参数：保留价和拍卖时间（开始时间和结束时间）
    constructor(uint256 _reservePrice, uint256 _auctionDuration) Ownable(msg.sender) ERC721("WTF English Auction", "WTF English Auction") {
        reservePrice = _reservePrice;
        auctionStartTime = block.timestamp;
        auctionEndTime = auctionStartTime + _auctionDuration;
    }

    /**
     * ERC721Enumerable中totalSupply函数的实现
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * Private函数，在_allTokens中添加一个新的token
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokens.push(tokenId);
    }

    // 出价函数：参与拍卖
    function bid() external payable {
        require(block.timestamp >= auctionStartTime, "Auction has not started yet.");
        require(block.timestamp <= auctionEndTime, "Auction has ended.");
        require(msg.value > highestBid, "There already is a higher bid.");

        // 如果不是第一次出价，则退还之前的最高出价
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        // 更新最高出价者及其出价金额
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    // 提取被超出的出价（可以让出价失败的用户提取他们的钱）
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw.");

        pendingReturns[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    // 结束拍卖并分发NFT
    function endAuction() external onlyOwner {
        require(block.timestamp > auctionEndTime, "Auction is still ongoing.");
        require(!auctionEnded, "Auction has already ended.");

        auctionEnded = true;

        if (highestBid >= reservePrice) {
            // 拍卖成功：mint NFT给最高出价者
            uint256 mintIndex = totalSupply();
            _mint(highestBidder, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);

            // 提款：转移拍卖所得给合约拥有者
            payable(owner()).transfer(highestBid);
        } else {
            // 如果最高出价未达到保留价，退款给最高出价者
            pendingReturns[highestBidder] += highestBid;
        }
    }

    // BaseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // BaseURI setter函数, onlyOwner
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // 提款函数，允许项目方提取资金（除了拍卖所得以外的余额）
    function withdrawMoney() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }
}

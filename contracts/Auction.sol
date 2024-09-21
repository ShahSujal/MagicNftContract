// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 NFTId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Auction {
    IERC721 public nftContract;
    uint256 public AuctionId;

    constructor(address _nftContract) {
        nftContract = IERC721(_nftContract);
    }

    receive() external payable {}

    struct AuctionDetails {
        uint256 nftId;
        address owner;
        uint256 startPrice;
        address highestBidder;
        uint256 highestBid;
        bool status;
        uint256 startDate;
        uint256 endDate;
    }

    AuctionDetails[] public auctions;

    mapping(uint256 => AuctionDetails) public AuctionNFTDetails;
    mapping(address => mapping(uint256 => uint256)) public balanceOfowner;

    function ListNFT(
        uint256 nftId,
        uint256 startprice,
        uint256 endDateInsec
    ) public {
        require(
            nftContract.ownerOf(nftId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(
            block.timestamp + endDateInsec > block.timestamp,
            "End date should be greater than current time"
        );
        AuctionDetails memory newAuction = AuctionDetails(
            nftId,
            msg.sender,
            startprice,
            address(0),
            0,
            true,
            block.timestamp,
            block.timestamp + endDateInsec
        );
        auctions.push(newAuction);
        AuctionNFTDetails[AuctionId] = newAuction;
        AuctionId += 1;
    }

    function Bid(uint256 _AuctionId) public payable {
        require(
            AuctionNFTDetails[_AuctionId].owner != msg.sender,
            "Owner cannot bid own nft"
        );
        require(
            msg.value > AuctionNFTDetails[_AuctionId].highestBid,
            "Your bid should be greater than the highest bid."
        );
        require(
            AuctionNFTDetails[_AuctionId].highestBidder != msg.sender,
            "Your are the highest bidder, You can't bid again !"
        );
        AuctionNFTDetails[_AuctionId].highestBid = msg.value;
        AuctionNFTDetails[_AuctionId].highestBidder = msg.sender;
        balanceOfowner[msg.sender][_AuctionId] =
            balanceOfowner[msg.sender][_AuctionId] +
            msg.value;
    }

    function withdrawFunds(uint256 _AuctionId) public {
        require(
            AuctionNFTDetails[_AuctionId].highestBidder != msg.sender,
            "You are the highest bidder you can't withdraw"
        );
        payable(msg.sender).transfer(balanceOfowner[msg.sender][_AuctionId]);
        balanceOfowner[msg.sender][_AuctionId] = 0;
    }

    function completeAuction(uint256 _AuctionId) public {
        require(
            AuctionNFTDetails[_AuctionId].endDate < block.timestamp,
            "Auction is not completed yet"
        );
        require(
            AuctionNFTDetails[_AuctionId].owner == msg.sender,
            "You are not the owner of this NFT"
        );
        nftContract.transferFrom(
            AuctionNFTDetails[_AuctionId].owner,
            AuctionNFTDetails[_AuctionId].highestBidder,
            AuctionNFTDetails[_AuctionId].nftId
        );
        
    }
}
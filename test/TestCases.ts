import { ethers } from "hardhat";
import { expect } from "chai";
import { MyToken, Marketplace, Auction } from "../typechain-types";

describe("NFT, Marketplace, and Auction contracts", function () {
  let nftContract: MyToken;
  let marketplace: Marketplace;
  let auction: Auction;
  let owner: any, buyer: any, bidder1: any, bidder2: any;

  before(async function () {
    [owner, buyer, bidder1, bidder2] = await ethers.getSigners();

    // Deploy MyToken (NFT contract)
    const NFTFactory = await ethers.getContractFactory("MyToken");
    nftContract = (await NFTFactory.deploy("MyNFT", "MNFT")) as MyToken;
    await nftContract.getDeployedCode();

    // Deploy Marketplace contract
    const MarketplaceFactory = await ethers.getContractFactory("Marketplace");
    marketplace = (await MarketplaceFactory.deploy()) as Marketplace;
    await marketplace.getDeployedCode();

    // Deploy Auction contract
    const AuctionFactory = await ethers.getContractFactory("Auction");
    auction = (await AuctionFactory.deploy(nftContract.getAddress())) as Auction;
    await auction.getDeployedCode();
  });

  describe("MyToken Contract", function () {
    it("Should mint a new NFT", async function () {
      await nftContract.safeMint("ipfs://tokenURI1");
      expect(await nftContract.ownerOf(0)).to.equal(owner.address);
    });
  });

  describe("Marketplace Contract", function () {
    it("Should list NFT for sale", async function () {
      await nftContract.approve(marketplace.getAddress(), 0);
      await marketplace.createListing(0, nftContract.getAddress(), ethers.parseEther("1"));
      const listing = await marketplace.getMarketItem(1);
      expect(listing.seller).to.equal(owner.address);
    });

    it("Should allow purchase of listed NFT", async function () {
      await marketplace.connect(buyer).buyListing(1, nftContract.getAddress(), {
        value: ethers.parseEther("1"),
      });
      expect(await nftContract.ownerOf(0)).to.equal(buyer.address);
    });
  });

  describe("Auction Contract", function () {
    it("Should list NFT for auction", async function () {
      await nftContract.connect(buyer).approve(auction.getAddress(), 0);
      await auction.connect(buyer).ListNFT(0, ethers.parseEther("1"), 60 * 60); // 1 hour auction
      const auctionDetails = await auction.AuctionNFTDetails(0);
      expect(auctionDetails.owner).to.equal(buyer.address);
    });

    it("Should allow bidding on the auction", async function () {
      await auction.connect(bidder1).Bid(0, { value: ethers.parseEther("1.5") });
      await auction.connect(bidder2).Bid(0, { value: ethers.parseEther("2") });
      const highestBidder = (await auction.AuctionNFTDetails(0)).highestBidder;
      expect(highestBidder).to.equal(bidder2.address);
    });

    it("Should complete the auction and transfer the NFT", async function () {
      // Move time forward to complete the auction
      await ethers.provider.send("evm_increaseTime", [60 * 60 + 1]);
      await auction.connect(buyer).completeAuction(0);
      expect(await nftContract.ownerOf(0)).to.equal(bidder2.address);
    });
  });
});

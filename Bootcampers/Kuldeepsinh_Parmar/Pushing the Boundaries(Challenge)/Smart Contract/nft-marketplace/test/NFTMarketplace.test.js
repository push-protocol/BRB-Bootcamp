const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  let NFTMarketplace, nftMarketplace, owner, artist, buyer, addrs;
  let SUBSCRIPTION_ID, CALLBACK_GAS_LIMIT;

  beforeEach(async function () {
    [owner, artist, buyer, ...addrs] = await ethers.getSigners();

    SUBSCRIPTION_ID = 1234; // Example subscription ID
    CALLBACK_GAS_LIMIT = 100000;

    NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    nftMarketplace = await NFTMarketplace.deploy(SUBSCRIPTION_ID, CALLBACK_GAS_LIMIT);
    await nftMarketplace.waitForDeployment();
  });

  describe("Minting and Fractionalization", function () {
    it("Should mint and fractionalize an NFT", async function () {
      const tokenURI = "https://example.com/token.json";
      const nftName = "Test NFT";
      const nftDescription = "A test NFT";
      const shardPrices = [100, 200, 300, 400, 500, 600, 700, 800, 900];

      await expect(nftMarketplace.connect(artist).mintAndFractionalize(tokenURI, nftName, nftDescription, shardPrices))
        .to.emit(nftMarketplace, "NFTMinted")
        .and.to.emit(nftMarketplace, "NFTFractionalized");

      const nftInfo = await nftMarketplace.getNFTInfo(1);
      expect(nftInfo.name).to.equal(nftName);
      expect(nftInfo.description).to.equal(nftDescription);
      expect(nftInfo.fractionalized).to.be.true;

      // Check if all shards are minted to the artist
      for (let i = 2; i <= 10; i++) {
        expect(await nftMarketplace.ownerOf(i)).to.equal(artist.address);
      }
    });
  });
  
  describe("Listing and Buying Shards", function () {
    beforeEach(async function () {
      await nftMarketplace.connect(artist).mintAndFractionalize(
        "https://example.com/token.json",
        "Test NFT",
        "A test NFT",
        [100, 200, 300, 400, 500, 600, 700, 800, 900]
      );
    });

    it("Should list a shard for sale", async function () {
      await expect(nftMarketplace.connect(artist).listShard(2, 150))
        .to.emit(nftMarketplace, "ShardListed")
        .withArgs(2, 150);

      const shardInfo = await nftMarketplace.getShardInfo(2);
      expect(shardInfo.forSale).to.be.true;
      expect(shardInfo.price).to.equal(150);
    });

    it("Should buy a listed shard", async function () {
      await nftMarketplace.connect(artist).listShard(2, 150);

      await expect(nftMarketplace.connect(buyer).buyShard(2, { value: 150 }))
        .to.emit(nftMarketplace, "ShardSold")
        .withArgs(2, artist.address, buyer.address, 150);

      expect(await nftMarketplace.ownerOf(2)).to.equal(buyer.address);
    });
  });

  describe("NFT Reconstruction", function () {
    beforeEach(async function () {
      await nftMarketplace.connect(artist).mintAndFractionalize(
        "https://example.com/token.json",
        "Test NFT",
        "A test NFT",
        [100, 100, 100, 100, 100, 100, 100, 100, 100]
      );

      // List and sell all shards to the buyer
      for (let i = 2; i <= 10; i++) {
        await nftMarketplace.connect(artist).listShard(i, 100);
        await nftMarketplace.connect(buyer).buyShard(i, { value: 100 });
      }
    });

    it("Should reconstruct the NFT when all shards are collected", async function () {
      // The last buyShard call should trigger the reconstruction
      await expect(nftMarketplace.connect(buyer).buyShard(10, { value: 100 }))
        .to.emit(nftMarketplace, "NFTReconstructed")
        .withArgs(1, buyer.address, 900); // 900 is the total value of all shards

      // Check if the original NFT is transferred to the buyer
      expect(await nftMarketplace.ownerOf(1)).to.equal(buyer.address);

      // Check if all shards are burned
      for (let i = 2; i <= 10; i++) {
        await expect(nftMarketplace.ownerOf(i)).to.be.revertedWith("ERC721: invalid token ID");
      }
    });
  });

  describe("Hashing and Verification", function () {
    beforeEach(async function () {
      await nftMarketplace.connect(artist).mintAndFractionalize(
        "https://example.com/token.json",
        "Test NFT",
        "A test NFT",
        [100, 200, 300, 400, 500, 600, 700, 800, 900]
      );
    });

    it("Should verify artist-NFT relationship", async function () {
      expect(await nftMarketplace.verifyArtistNFT(artist.address, 1)).to.be.true;
      expect(await nftMarketplace.verifyArtistNFT(buyer.address, 1)).to.be.false;
    });

    it("Should verify shard ownership", async function () {
      expect(await nftMarketplace.verifyShardOwnership(2, artist.address)).to.be.true;
      expect(await nftMarketplace.verifyShardOwnership(2, buyer.address)).to.be.false;

      // Transfer a shard and check again
      await nftMarketplace.connect(artist).listShard(2, 150);
      await nftMarketplace.connect(buyer).buyShard(2, { value: 150 });

      expect(await nftMarketplace.verifyShardOwnership(2, artist.address)).to.be.false;
      expect(await nftMarketplace.verifyShardOwnership(2, buyer.address)).to.be.true;
    });
  });
});
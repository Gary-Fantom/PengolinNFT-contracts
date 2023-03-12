const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Token", function () {
  let PengolinNft, pengolinNft, owner, addr1, addr2;

  beforeEach(async () => {
    [owner, addr1, addr2, _] = await ethers.getSigners();
    const deployerAddress = owner.address;

    const baseUri = "https://static.pengolincoin.xyz/arts/jsons/";
    const feeNumerator = 1000; // royalty is 10%
    const maxSupply = 5000;

    const PengolinNft = await hre.ethers.getContractFactory("PengolinNft");
    const pengolinNft = await PengolinNft.deploy(
      "PengolinNft",
      "PGN",
      baseUri,
      maxSupply,
      deployerAddress,
      feeNumerator
    );

    await pengolinNft.deployed();
    console.log("PengolinNft Contract deployed to:", pengolinNft.address);

    const PengolinToken = await hre.ethers.getContractFactory("PengolinToken");
    const pengolinToken = await PengolinToken.deploy("PengolinToken", "PGO");

    await pengolinToken.deployed();
    console.log("PengolinToken Contract deployed to:", pengolinToken.address);

    console.log(pengolinToken.address, "--pengolinToken");

    const PengolinSwap = await hre.ethers.getContractFactory("PengolinSwap");
    const pengolinSwap = await PengolinSwap.deploy(pengolinToken.address);

    await pengolinToken.deployed();
    console.log("PengolinSwap Contract deployed to:", pengolinSwap.address);

    console.log(pengolinSwap.address, "--pengolinSwap");
    pengolinToken.addController(pengolinSwap.address);
  });

  describe("Verify a signature", () => {
    it("Verify a signature of the owner", async () => {
      const value = ethers.utils.parseEther("200");
      const tx = await pengolinNft.connect(addr1).claim(1, { value });
      const txd = await tx.wait();

      const tx2 = await pengolinNft.connect(addr2).claim(1, { value });
      const txd2 = await tx2.wait();

      const _contractInfo = await pengolinNft.contractInfo();
      const total = ethers.utils.parseEther("400");
      expect(_contractInfo.countClaims).to.equal(2);
    });
  });
});

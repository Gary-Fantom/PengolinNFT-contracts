// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
var ethers = require('ethers');
const hre = require("hardhat");

async function main() {
  // const [deployer, firstAcct, secondAcct] = await hre.ethers.getSigners();
  const [deployer, firstAcct, secondAcct] = await hre.ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );

  const baseUri = "https://static.pengolincoin.xyz/arts/jsons/";
  const feeNumerator = 1000; // royalty is 10%
  const maxSupply = 5000;

  const PengolinNft = await hre.ethers.getContractFactory("PengolinNft");
  const pengolinNft = await PengolinNft.deploy('PengolinNft', 'PGN', baseUri, maxSupply, deployer.address, feeNumerator);

  await pengolinNft.deployed();
  console.log("PengolinNft Contract deployed to:", pengolinNft.address);

  console.log(deployer.address, '--deployerAddress');
  console.log(pengolinNft.address, '--pengolinNft');
  console.log(maxSupply, '--max supply');
  console.log(feeNumerator, '--royalty');

  const PengolinToken = await hre.ethers.getContractFactory("PengolinToken");
  const pengolinToken = await PengolinToken.deploy('PengolinToken', 'PGO');

  await pengolinToken.deployed();
  console.log("PengolinToken Contract deployed to:", pengolinToken.address);

  console.log(pengolinToken.address, '--pengolinToken');

  const PengolinSwap = await hre.ethers.getContractFactory("PengolinSwap");
  const pengolinSwap = await PengolinSwap.deploy(pengolinToken.address);

  await pengolinToken.deployed();
  console.log("PengolinSwap Contract deployed to:", pengolinSwap.address);

  console.log(pengolinSwap.address, '--pengolinSwap');
  await pengolinToken.addController(pengolinSwap.address);

  // const betAmount = 10;
  // const feePercent = 1000;
  // const playerCountOfRoom = 4;
  // const PengolinSprayer = await hre.ethers.getContractFactory("PengolinSprayer");
  // const pengolinSprayer = await PengolinSprayer.deploy("0x8c12DDa5AdDdB272BEc77C70a8F32331dAE9F6F3", "0x3b5b99CB4225c72eC32C16897126Df6bFa3Da109",
  //    betAmount, feePercent, playerCountOfRoom);
  // await pengolinSprayer.deployed();
  // console.log(pengolinSprayer.address, "--pengolinSprayer");

  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

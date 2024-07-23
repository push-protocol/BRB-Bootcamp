const hre = require("hardhat");

async function main() {
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarketplace");
  
  // Replace these with your actual constructor arguments
  const subscriptionId = 113036415537163141537940078842313160028336713387877844916459818797196002945578;
  const callbackGasLimit = 1000000;

  const nftMarketplace = await NFTMarketplace.deploy(subscriptionId, callbackGasLimit);

  await nftMarketplace.waitForDeployment();

  console.log("NFTMarketplace deployed to:", await nftMarketplace.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
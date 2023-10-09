
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying NftRaffle contract with the account:", deployer.address);

  const NftRaffle = await ethers.getContractFactory("NftRaffle");
  const entryCost = 100; // Set the initial entry cost as needed

  const raffleContract = await NftRaffle.deploy(entryCost);

  await raffleContract.deployed();

  console.log("NftRaffle contract deployed to:", raffleContract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

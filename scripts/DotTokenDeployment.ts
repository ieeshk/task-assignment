import hre from "hardhat";

async function main() {
  const DotToken = await hre.ethers.getContractFactory("DOTToken");
  const dotToken = await DotToken.deploy();

  await dotToken.deployed();

  console.log("DotToken contract address: ", dotToken.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


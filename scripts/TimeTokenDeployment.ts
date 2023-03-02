import hre from "hardhat";

async function main() {
  const TimeToken = await hre.ethers.getContractFactory("TimeToken");
  const timeToken = await TimeToken.deploy();

  await timeToken.deployed();

  console.log("TimeToken contract address: ", timeToken.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
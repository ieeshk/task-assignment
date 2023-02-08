import hre from "hardhat";

async function main() {
  const DonutToken = await hre.ethers.getContractFactory("DONUTToken");
  const donutToken = await DonutToken.deploy();

  await donutToken.deployed();

  console.log("DonutToken contract address: ", donutToken.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

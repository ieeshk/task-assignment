import hre from "hardhat";

async function main() {
  
    const DotToken = await hre.ethers.getContractFactory("DOTToken");
  const dotToken = await DotToken.deploy();
  
  await dotToken.deployed();
  
  console.log("DotToken contract address: ", dotToken.address);

  const DonutToken = await hre.ethers.getContractFactory("DONUTToken");
  const donutToken = await DonutToken.deploy();

  await donutToken.deployed();
  
  console.log("DonutToken contract address: ", donutToken.address);

  const StakingPool = await hre.ethers.getContractFactory("StakingRewardsNew");

  const stakingPool = await StakingPool.deploy(dotToken.address, donutToken.address);

  await stakingPool.deployed();

  console.log("Staking pool contract address: ", stakingPool.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

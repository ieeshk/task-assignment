import hre from "hardhat";

async function main() {
  
  const NewToken = await hre.ethers.getContractFactory("MyToken");
  const newToken = await NewToken.deploy();

  await newToken.deployed();

  console.log("myToken contract address: ", newToken.address);
  
  const StakingPool = await hre.ethers.getContractFactory("lockedTokens");

  const stakingPool = await StakingPool.deploy(newToken.address);

  await stakingPool.deployed();

  console.log("Staking pool contract address: ", stakingPool.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { waffle } from "hardhat";
import { BigNumber as BN } from "bignumber.js";
import exp from "constants";

async function forward(seconds: any) {
  const lastTimestamp = (await waffle.provider.getBlock("latest")).timestamp;
  await waffle.provider.send("evm_setNextBlockTimestamp", [
  lastTimestamp + seconds,
  ]);
  await waffle.provider.send("evm_mine", []);
}

describe("Staking Test Cases", () => {
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let stakingContract: ContractFactory;
    let StakingToken: ContractFactory;
    let RewardToken: ContractFactory;
    let stakingToken: Contract;
    let rewardToken: Contract;
    let stakingPool: Contract;
    let stakeAmount: BigNumber;
    let transferAmount: BigNumber;
    let approvalAmount: BigNumber;
    let rewardAmount: BigNumber;
    let penaltyRewards: BigInt;
describe("Reward testcase", () => {
    beforeEach(async () => {
    [owner, user1] = await ethers.getSigners();
    StakingToken = await ethers.getContractFactory("DOTToken", owner);
    stakingToken = await StakingToken.deploy();
    stakingToken.deployed();
    RewardToken = await ethers.getContractFactory("DONUTToken", owner);
    rewardToken = await RewardToken.deploy();
    rewardToken.deployed();
    stakingContract = await ethers.getContractFactory("StakingRewards", owner);
    stakingPool = await stakingContract.deploy(stakingToken.address, rewardToken.address);
    stakingPool.deployed();
    transferAmount = BigNumber.from("1000000000000000000000");
    rewardAmount = BigNumber.from("100000000000000000000");
    stakeAmount = ethers.utils.parseEther("100");
    approvalAmount = BigNumber.from("1000000000000000000000000000000000000");
    await stakingToken
    .connect(owner)
    .approve(stakingPool.address, approvalAmount);
    await rewardToken
    .connect(owner)
    .approve(stakingPool.address, approvalAmount);
    await rewardToken.connect(owner).transferOwnership(stakingPool.address);
    });
    
it("Stake tokens and check balance ", async function () {
    
    const rewardRate = await stakingPool.connect(owner).rewardRate();
    
    await stakingPool.connect(owner).stake(transferAmount);
    await forward(1000);

    //Earn rewards for 4 tokens per second for 1000 seconds
    const earnedAmount =await stakingPool.connect(owner).earned(owner.address)
    expect(BigInt(earnedAmount)).to.equal(BigInt(rewardRate) * BigInt(1000));
    

    const RewardsAmount = await stakingPool.connect(owner).rewards(owner.address);
    expect(RewardsAmount).to.equal(0);

    await stakingPool.connect(owner).stake(transferAmount);

    //new rewards after second stake to be earned Rewards plus rewards for 1 sec
    const RewardsAmount2 = await stakingPool.connect(owner).rewards(owner.address);
    expect(RewardsAmount2).to.equal(earnedAmount.add(rewardRate));
    //console.log('rewards amount after 2nd stake', RewardsAmount2);

    // const rewardPerToken = await stakingPool.connect(owner).rewardPerToken();
    // console.log("reward PerToken", rewardPerToken);

    // const userRewardPerTokenPaid = await stakingPool.connect(owner).userRewardPerTokenPaid(owner.address);
    // console.log("user reward per token paid", userRewardPerTokenPaid);

    //await stakingPool.connect(owner).withdraw(transferAmount);


});

it("Stake tokens, then withdraw & check reward tokens received ", async function () {
    
    const rewardRate = await stakingPool.connect(owner).rewardRate();
    
    await stakingPool.connect(owner).stake(transferAmount);
    await forward(1000);

    await stakingPool.connect(owner).stake(transferAmount);
    
    //penalty is applied on 
    await stakingPool.connect(owner).withdraw(transferAmount);

    const rewardAmount = await rewardToken.connect(owner).balanceOf(owner.address);
    //console.log("reward Amount received", rewardAmount);


});

it("Check cooldown period ", async function () {
    
    await stakingPool.connect(owner).stake(transferAmount);
    await forward(1000);

    await stakingPool.connect(owner).stake(transferAmount);

    await expect(stakingPool.connect(owner).withdraw(transferAmount)).to.be.revertedWith("CoolDown time not completed");
    
    //wait for cooldown period to complete

    await forward(1000000000000);

    await stakingPool.connect(owner).withdraw(transferAmount);


});

});
});

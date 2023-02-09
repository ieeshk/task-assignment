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
    let transferAmount2: BigInt;
describe("Reward testcase", () => {
    beforeEach(async () => {
    [owner, user1] = await ethers.getSigners();
    StakingToken = await ethers.getContractFactory("DOTToken", owner);
    stakingToken = await StakingToken.deploy();
    stakingToken.deployed();
    RewardToken = await ethers.getContractFactory("DONUTToken", owner);
    rewardToken = await RewardToken.deploy();
    rewardToken.deployed();
    stakingContract = await ethers.getContractFactory("StakingRewardsNew", owner);
    stakingPool = await stakingContract.deploy(stakingToken.address, rewardToken.address);
    stakingPool.deployed();
    transferAmount = BigNumber.from("1000000000000000000000");
    transferAmount2 = BigInt("1000000000000000000000");
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

it("Stake tokens, then withdraw without penalty", async function () {
    
    await stakingPool.connect(owner).stake(transferAmount);
    await forward(1000);

    await stakingPool.connect(owner).stake(transferAmount);
    
    const balanceAfterStake = await stakingToken.connect(owner).balanceOf(owner.address);
    //console.log("balance after stake", balanceAfterStake);

    await stakingPool.connect(owner).cooldown();
    
    await forward(100000);
    
    //no penalty is applied on as last stake is also unlocked
    await stakingPool.connect(owner).withdraw(transferAmount);
    
    const balanceAfterWithdraw = await stakingToken.connect(owner).balanceOf(owner.address);
    
    expect(balanceAfterWithdraw).to.equal(balanceAfterStake.add(transferAmount));

});
it("Stake tokens, then withdraw & under with penalty", async function () {
    
    const owner_balance = await stakingToken.balanceOf(owner.address);
    console.log("owner balance", owner_balance);

    await stakingToken.connect(owner).transfer(user1.address, transferAmount);
    await stakingToken.connect(user1).approve(stakingPool.address, transferAmount);

    await stakingPool.connect(user1).stake(transferAmount);
    await stakingPool.connect(user1).cooldown();
    await forward(500);

    // await stakingPool.connect(owner).stake(transferAmount);
    
    const balanceAfterStake = await stakingToken.connect(user1).balanceOf(user1.address);
    //console.log("balance after stake", balanceAfterStake);

    const balanceAfterStakeinContract = await stakingPool.connect(user1).balanceOf(user1.address);
    //console.log("balance after stake", balanceAfterStakeinContract);


    const lastStakeTime = await stakingPool.connect(user1).lastStake(user1.address);
    //console.log("last stake time", lastStakeTime);
    const lockDuration = await stakingPool.lockDuration();

    const totalStakeTime = lastStakeTime.add(lockDuration);
    //console.log("total stake time in con", totalStakeTime);

    // let timeDuration: number;
    // timeDuration = 502;
    let lastTimestamp: any;
    lastTimestamp = (await waffle.provider.getBlock("latest")).timestamp;

    //extra 1 second when function calls
    const timeDuration = lastTimestamp - lastStakeTime + 1;
    //console.log("time duration now", timeDuration);

    
    const totalRewards = (timeDuration * Number(transferAmount))/totalStakeTime;
    //console.log("total Rewards given to owner", totalRewards);
    //penalty is applied as stake is still locked
    await stakingPool.connect(user1).withdraw(transferAmount);
    
    const ownerBalanceAfterWithdraw = await stakingToken.connect(owner).balanceOf(owner.address);
    //console.log("penalty owner received", ownerBalanceAfterWithdraw);

    const balanceReceivedByUser = await stakingToken.connect(user1).balanceOf(user1.address);
    //console.log("balance received by user", balanceReceivedByUser);

    //const ownerBalanceDifferernce = owner_balance.sub(ownerBalanceAfterWithdraw);
    //owner received some percentage tokens since user withdraws within penalty period

    //expect(owner_balance.sub(transferAmount).sub(ownerBalanceAfterWithdraw).add(totalRewards).toFixed()).to.equal(0);
    
    // expect(balanceAfterWithdraw).to.equal(balanceAfterStake.add(transferAmount));
});

it("Withdraw without cooldown period set ", async function () {
    
    await stakingPool.connect(owner).stake(transferAmount);
    await forward(1000);

    await expect(stakingPool.connect(owner).withdraw(approvalAmount)).to.be.revertedWith("Low Balance");

    await expect(stakingPool.connect(owner).withdraw(transferAmount)).to.be.revertedWith("Set cooldown timer First");
    
    await stakingPool.connect(owner).cooldown();
    
    //wait for cooldown period to complete

    await forward(1000000000000);

    await stakingPool.connect(owner).withdraw(transferAmount);


});

it("Set cooldown period ", async function () {
    
    await stakingPool.connect(owner).stake(transferAmount);
    await forward(1000);

    await stakingPool.connect(owner).stake(transferAmount);

    await stakingPool.connect(owner).cooldown();

    await expect(stakingPool.connect(owner).withdraw(transferAmount)).to.be.revertedWith("Timer not completed");
    
    //wait for cooldown period to complete

    await forward(1000000000000);

    await stakingPool.connect(owner).withdraw(transferAmount);


});

it("Cannot unstake zero Amount", async function () {
    await expect(stakingPool.connect(owner).withdraw(0)).to.be.revertedWith(
      "amount should be greater than zero"
    );
});

it("withdraw some staked tokens and check total Supply", async function () {

    await stakingPool.connect(owner).stake(stakeAmount);

    await stakingPool.connect(owner).stake(stakeAmount);

    const userBalance = await stakingPool.balanceOf(owner.address);
    const totalSupply = await stakingPool.totalSupply();

    const unstakeAmount = "1000000000000";

    await stakingPool.connect(owner).cooldown();

    await forward(10000);

    await stakingPool.connect(owner).withdraw(unstakeAmount);

    const userBalanceAfter = await stakingPool.balanceOf(owner.address);
    const totalSupplyAfter = await stakingPool.totalSupply();

    expect(userBalance.sub(userBalanceAfter)).to.equal(unstakeAmount);

    expect(totalSupply.sub(totalSupplyAfter)).to.equal(unstakeAmount);
});

it("Calculate claimable earned tokens and mint for owner", async function () {

    await stakingPool.connect(owner).stake(stakeAmount);

    await forward(30);

    const totalUserBalance = await stakingPool.balanceOf(owner.address);

    const totalSupply = await stakingPool.totalSupply();

    const rewardRate = await stakingPool.rewardRate();

    const totalRewardsAccumlated = rewardRate * 30;
    //console.log("total rewards accumulated", totalRewardsAccumlated);

    const calculatedUserRewards = BN(
      totalUserBalance.toString()
    ).multipliedBy(
      BN(totalRewardsAccumlated.toString()).div(totalSupply.toString())
    );

    const userRewards = await stakingPool.earned(owner.address);
    //console.log("user rewards via earned function", userRewards);

    expect(userRewards).to.equal(
      (calculatedUserRewards).toString()
    );

    const rewardBalanceBefore = await rewardToken.connect(owner).balanceOf(owner.address);
    //console.log("reward balance before", rewardBalanceBefore);

    await stakingPool.connect(owner).claim();
    
    const rewardBalanceAfter = await rewardToken.connect(owner).balanceOf(owner.address);
    //console.log("reward balance after", rewardBalanceAfter);

    expect(rewardBalanceBefore).to.equal(0);
    //include reward accumulated in 30 sec + 1sec
    expect(rewardBalanceAfter).to.equal(rewardBalanceBefore.add(userRewards).add(rewardRate));


  });
  it("Test buy staking tokens with Eth", async function(){
    // const ownerEthBalance = await ethers.provider.getBalance(owner.address);
    // console.log("owner eth balance", ownerEthBalance);

    const userEthBalance = await ethers.provider.getBalance(user1.address);
    //console.log("user eth balance", userEthBalance);

    const userBalanceBefore = await stakingToken.connect(user1).balanceOf(user1.address);
    //console.log("user balance before", userBalanceBefore);

    let newAmount: BigNumber = ethers.utils.parseEther("1");

    // const path = [weth, stakingToken];

    // let result = await routerInstance.getAmountsOut(transferAmount, path);

    await stakingToken.connect(owner).transfer(user1.address, transferAmount);
    await stakingToken.connect(user1).approve(stakingPool.address, transferAmount);

    const balanceBefore = await stakingToken.connect(user1).balanceOf(user1.address);
    //console.log("balance Before", balanceBefore);
    
    await stakingPool.connect(user1).addLiquidityEth(transferAmount, {value:newAmount});
    

    const userBalanceAfter = await stakingToken.connect(user1).balanceOf(user1.address);
    //console.log("user balance after", userBalanceAfter);

    //liquidity added and no staking token left
    expect(userBalanceAfter).to.equal(0);

    // await stakingPool.connect(user1).buyDotToken(newAmount);

    // const userBalanceAfterBuy = await stakingToken.connect(user1).balanceOf(user1.address);
    // console.log("user balance after", userBalanceAfterBuy);



  });






  


});
});

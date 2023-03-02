import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { waffle } from "hardhat";
import { BigNumber as BN } from "bignumber.js";
import exp from "constants";
import axios from "axios";

async function forward(seconds: any) {
    const lastTimestamp = (await waffle.provider.getBlock("latest")).timestamp;
    await waffle.provider.send("evm_setNextBlockTimestamp", [
    lastTimestamp + seconds,
    ]);
    await waffle.provider.send("evm_mine", []);
  }

describe("Token Contract", () => {
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let TimeToken: ContractFactory;
    let timeToken: Contract;
    let stakeAmount: BigNumber;
    let transferAmount: BigNumber;
    let approvalAmount: BigNumber;
    let rewardAmount: BigNumber;
    let transferAmount2: BigInt;
    const zeroAddress = "0x0000000000000000000000000000000000000000";
    const myAddress = "0xa66f9e9310374f9e9bbAf1aB5030d40A7C070489";

  beforeEach(async function () {

    [owner, user1, user2] = await ethers.getSigners();
    TimeToken = await ethers.getContractFactory("TimeToken", owner);
    timeToken = await TimeToken.deploy();
    timeToken.deployed();
    //console.log("my token address", stakingToken.address);
    transferAmount = BigNumber.from("1000000000000000000000");
    transferAmount2 = BigInt("1000000000000000000000");
    rewardAmount = BigNumber.from("100000000000000000000");
    stakeAmount = ethers.utils.parseEther("100");
    approvalAmount = BigNumber.from("1000000000000000000000000000000000000");

  });

  describe("Test Lock & Unlock", function () {
    it("Mint and initiate transfer", async function () {
        await timeToken.connect(owner).mint(transferAmount);
        const ownerBalance = await timeToken.connect(owner).balanceOf(owner.address);
        await timeToken.connect(owner).initateTransfer(transferAmount, 6000, user1.address);
        const contractBalance = await timeToken.connect(owner).balanceOf(timeToken.address);
        console.log("contract balance", contractBalance);
    
    });

    it("Mint and initiate transfer and check claimable balance", async function () {
        await timeToken.connect(owner).mint(transferAmount);
        const ownerBalance = await timeToken.connect(owner).balanceOf(owner.address);
        await timeToken.connect(owner).initateTransfer(transferAmount, 6000, user1.address);
        const contractBalance = await timeToken.connect(owner).balanceOf(timeToken.address);
        await forward(500);
        const claimableBalance = await timeToken.connect(user1).claimableAmount();
        const transferRateUser1 = await timeToken.connect(user1)._rewardRate(user1.address);
        //console.log("transfer rate of user 1", transferRateUser1);
        //console.log("claimable amount of user1", claimableBalance);
        expect(Number(claimableBalance)).to.equal(Number(transferRateUser1) * Number(500));
    
    });

    it("Mint and initiate transfer and check claimable balance and claim amount", async function () {
        await timeToken.connect(owner).mint(transferAmount);
        const ownerBalance = await timeToken.connect(owner).balanceOf(owner.address);
        await timeToken.connect(owner).initateTransfer(transferAmount, 6000, user1.address);
        const contractBalance = await timeToken.connect(owner).balanceOf(timeToken.address);
        await forward(500);
        const claimableBalance = await timeToken.connect(user1).claimableAmount();
        const transferRateUser1 = await timeToken.connect(user1)._rewardRate(user1.address);
        //console.log("transfer rate of user 1", transferRateUser1);
        //console.log("claimable amount of user1", claimableBalance);
        const user1BalanceBefore = await timeToken.connect(user1).balanceOf(user1.address);
        console.log("user 1 balance before", user1BalanceBefore);
        await timeToken.connect(user1).claim();

        const claimableBalanceAfterClaim = await timeToken.connect(user1).claimableAmount();

        expect(claimableBalanceAfterClaim).to.equal(0);

        const user1BalanceAfter = await timeToken.connect(user1).balanceOf(user1.address);

        //console.log("user1 balance after", user1BalanceAfter);

        await forward(200);

        const claimableBalanceAfter = await timeToken.connect(user1).claimableAmount();

        //console.log("claimable balance for now 200 seconds", claimableBalanceAfter);

        expect(Number(claimableBalanceAfter)).to.equal(Number(transferRateUser1) * Number(200));



        
    
    });
});
});    
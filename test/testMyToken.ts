import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { waffle } from "hardhat";
import { BigNumber as BN } from "bignumber.js";
import exp from "constants";
import axios from "axios";

describe("Token Contract", () => {
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let stakingContract: ContractFactory;
    let StakingToken: ContractFactory;
    let stakingToken: Contract;
    let stakingPool: Contract;
    let stakeAmount: BigNumber;
    let transferAmount: BigNumber;
    let approvalAmount: BigNumber;
    let rewardAmount: BigNumber;
    let transferAmount2: BigInt;
    const zeroAddress = "0x0000000000000000000000000000000000000000";
    const myAddress = "0xa66f9e9310374f9e9bbAf1aB5030d40A7C070489";

  beforeEach(async function () {

    [owner, user1, user2] = await ethers.getSigners();
    StakingToken = await ethers.getContractFactory("MyToken");
    stakingToken = await StakingToken.deploy();
    stakingToken.deployed();
    //console.log("my token address", stakingToken.address);
    stakingContract = await ethers.getContractFactory("lockedTokens", owner);
    stakingPool = await stakingContract.deploy(stakingToken.address);
    stakingPool.deployed();
    transferAmount = BigNumber.from("1000000000000000000000");
    transferAmount2 = BigInt("1000000000000000000000");
    rewardAmount = BigNumber.from("100000000000000000000");
    stakeAmount = ethers.utils.parseEther("100");
    approvalAmount = BigNumber.from("1000000000000000000000000000000000000");

  });

  describe("Mint Test", function () {
    it("Should mint tokens when ether is passed", async function () {
    let newAmount: BigNumber = ethers.utils.parseEther("1");
      await expect(
        stakingToken.connect(user1).mint({value:0})
      ).to.be.revertedWith("Enter valid eth amount");
    });

    it("Should successfully mint", async function () {
        //let newAmount: BigNumber = ethers.utils.parseEther("1");
      await stakingToken.connect(user1).mint({value: transferAmount});
      const lockedBalance = await stakingToken.locked(user1.address);
      //expect(lockedBalance).to.equal(newAmount * 2);
      //console.log("mint balance", lockedBalance);
      //const totalBalance = stakingToken.connect(user1).balanceOf(user1.address);
      expect(Number(lockedBalance)).to.equal(Number(transferAmount)* Number(2));
    });
  });

  describe("Allowed Contract Test", function () {
    it("Zero Address not allowed", async function () {
    
      await expect(
        stakingToken.connect(owner).allowContract(zeroAddress)
      ).to.be.revertedWith("Not a valid Address");
    });
    
    it("Caller is not the owner", async function () {
    
        await expect(
          stakingToken.connect(user1).allowContract(zeroAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Account address is not allowed", async function () {
        await expect(
            stakingToken.connect(owner).allowContract(myAddress)
          ).to.be.revertedWith("Not a contract Address");
        
    });

    it("Successfully add contract address", async function () {
        
        stakingToken.connect(owner).allowContract(stakingPool.address);
        const contractStatus = await stakingToken.connect(owner).isAllowed(stakingPool.address);
        //console.log("contract status", contractStatus);
        expect(contractStatus).to.equal(true);
        
    });
  });


  
  describe("Transfer Test", function () {
    it("Should fail to transfer (do not have enough balance)", async function () {
      await expect(
        stakingToken.connect(user1).transfer(user2.address, "1000000000000000000")
      ).to.be.revertedWith("insufficient unlocked tokens");
    });

    // it("Should successfully transfer", async function () {
    //   await stakingToken.connect(owner).mint({value: transferAmount});
    //   await stakingToken.connect(owner).transfer(user1.address, transferAmount);

    //   expect(await stakingToken.balanceOf(user1.address)).to.equal(
    //     transferAmount
    //   );
    // });
    it("send locked tokens to allowed contracts", async function(){
        await stakingToken.connect(user1).mint({value: transferAmount});
        stakingToken.connect(owner).allowContract(stakingPool.address);

        stakingToken.connect(user1).transfer(stakingPool.address, transferAmount);
        const stakingPoolLocked = await stakingToken.connect(user1).locked(stakingPool.address);
        const userLockedBalance = await stakingToken.connect(user1).locked(user1.address);
        console.log("staking Pool locked tokens", stakingPoolLocked);
        expect(stakingPoolLocked).to.equal(transferAmount);
        //Half send to staking contract and rest half locked tokens remain
        expect(userLockedBalance).to.equal(transferAmount);


    });
    it("locked tokens balance is low to send to allowed contracts", async function(){
        await stakingToken.connect(user1).mint({value: transferAmount});
        stakingToken.connect(owner).allowContract(stakingPool.address);

        stakingToken.connect(user1).transfer(stakingPool.address, approvalAmount);
        expect(stakingToken.connect(user1).transfer(stakingPool.address, approvalAmount)).
        to.be.revertedWith(
            "insufficent locked tokens to transfer"
        );

    });
    it("Locked tokens are staked to allowed contract", async function(){
        await stakingToken.connect(user1).mint({value: transferAmount});
        await stakingToken.connect(owner).allowContract(stakingPool.address);

        await stakingToken.connect(user1).approve(stakingPool.address, transferAmount);
        const lockedBalanceBefore = await stakingToken.connect(user1).locked(user1.address);
        console.log("locked balance before", lockedBalanceBefore);
        //stakingToken.connect(stakingPool).transfer(user2.address, transferAmount);
        await stakingPool.connect(user1).stake(transferAmount);

        const balanceOfUser = await stakingPool.connect(user1).balanceOf(user1.address);
        console.log("balance of user", balanceOfUser);

        const lockedBalanceAfter = await stakingToken.connect(user1).locked(user1.address);
        console.log("locked balance after", lockedBalanceAfter);
        expect(BigInt(lockedBalanceBefore) - BigInt(lockedBalanceAfter)).to.equal(transferAmount.toString());



        // const stakingPoolLocked = await stakingToken.connect(user1).locked(stakingPool.address);
        // const user1LockedBalance = await stakingToken.connect(user1).locked(user1.address);
        //const user2UnlockedBalance = await stakingToken.connect(user2).unlocked(user2.address);
        // console.log("staking Pool locked tokens", stakingPoolLocked);
        //expect(stakingPoolLocked).to.equal(0);
        //Half send to staking contract and rest half locked tokens remain
        // expect(user1LockedBalance).to.equal(transferAmount);
         //expect(user2UnlockedBalance).to.equal(transferAmount);


    });

    it("Locked tokens are staked to allowed contract & Unlocked tokens are transfered back", async function(){
        await stakingToken.connect(user1).mint({value: transferAmount});
        await stakingToken.connect(owner).allowContract(stakingPool.address);

        await stakingToken.connect(user1).approve(stakingPool.address, transferAmount);
        const lockedBalanceBefore = await stakingToken.connect(user1).locked(user1.address);
        console.log("locked balance before", lockedBalanceBefore);
        //stakingToken.connect(stakingPool).transfer(user2.address, transferAmount);
        await stakingPool.connect(user1).stake(transferAmount);

        const balanceOfUser = await stakingPool.connect(user1).balanceOf(user1.address);
        console.log("balance of user", balanceOfUser);

        const lockedBalanceAfter = await stakingToken.connect(user1).locked(user1.address);
        console.log("locked balance after", lockedBalanceAfter);
        //expect(lockedBalanceBefore - lockedBalanceAfter).to.equal(transferAmount);

        await stakingPool.connect(user1).withdraw(transferAmount);

        const unlockedBalanceAfter = await stakingToken.connect(user1).unlocked(user1.address);
        //console.log("unlocked balance after", unlockedBalanceAfter);
        
        //const lockedBalanceAfterWithdraw = await stakingToken.connect(user1).locked(user1.address);
        //console.log("locked balance after withdraw", lockedBalanceAfterWithdraw);

        expect(unlockedBalanceAfter).to.equal(transferAmount);


    });

    it("Unlocked tokens are transferred to another user", async function(){
        await stakingToken.connect(user1).mint({value: transferAmount});
        await stakingToken.connect(owner).allowContract(stakingPool.address);

        await stakingToken.connect(user1).approve(stakingPool.address, transferAmount);
        const lockedBalanceBefore = await stakingToken.connect(user1).locked(user1.address);
        //console.log("locked balance before", lockedBalanceBefore);
        
        await stakingPool.connect(user1).stake(transferAmount);

        const balanceOfUser = await stakingPool.connect(user1).balanceOf(user1.address);
        //console.log("balance of user", balanceOfUser);

        const lockedBalanceAfter = await stakingToken.connect(user1).locked(user1.address);
        //console.log("locked balance after", lockedBalanceAfter);
        await stakingPool.connect(user1).withdraw(transferAmount);

        const unlockedBalanceAfter = await stakingToken.connect(user1).unlocked(user1.address);
        console.log("unlocked balance after", unlockedBalanceAfter);
    

        expect(unlockedBalanceAfter).to.equal(transferAmount);
        
        await stakingToken.connect(user1).transfer(user2.address, transferAmount);
        
        const unlockedBalanceUser2 = await stakingToken.connect(user2).unlocked(user2.address);
        //console.log("unlocked balance of user 2", unlockedBalanceUser2);
        expect(unlockedBalanceUser2).to.equal(transferAmount);
        

    });
    
  });

  describe("Approval/TransferFrom Test", function () {
    it("Should approve", async function () {
      await stakingToken.approve(user1.address, approvalAmount);
      expect(await stakingToken.allowance(owner.address, user1.address)).to.equal(
        approvalAmount
      );


    //   await expect(
    //     stakingToken.transferFrom(user1.address, user2.address, transferAmount2)
    //   ).to.be.revertedWith("not allowed to transfer");

    //   await stakingToken.connect(user1).approve(user2.address, approvalAmount);
    //   await stakingToken.connect(user1).transferFrom(user1.address, user2.address, transferAmount2);


    });

    // it("Should successfully transfer from user1 to user2", async function () {
        
    //   await stakingToken.connect(user1).mint({value: transferAmount});  
    //   //await stakingToken.transfer(user1.address, transferAmount);

    //   await stakingToken.connect(user1).approve(user2.address, approvalAmount);
    //   await stakingToken.transferFrom(user1.address, user2.address, transferAmount2);

    //   expect(await stakingToken.balanceOf(user2.address)).to.equal(transferAmount2);
    // });
  });
});
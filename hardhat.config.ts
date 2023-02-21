
import "@nomicfoundation/hardhat-toolbox";

import { task } from "hardhat/config";

import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

import { HardhatUserConfig /* , NetworkUserConfig */ } from "hardhat/types";

import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";

import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-contract-sizer";

import "@nomiclabs/hardhat-etherscan";


const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-goerli.g.alchemy.com/v2/tD0SU1xcediqc0M1tdxguEzpW9WrB9ZP`,
      },
    },
    goerli:{
      url:'https://goerli.infura.io/v3/3846354e4f0b4d3f8a52965f71e0b63c',
      accounts:["3266e35ee4299ee4f869563020417d4de8790b4ab7b9c15abe770602f87ac895"],
    },
  },
  etherscan: {
    apiKey: "5C38XQQAVKVS3IV4PXGWD7IWE6792I4XMF",
  },
};

export default config;

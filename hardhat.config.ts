
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
    goerli:{
      url:'https://goerli.infura.io/v3/3846354e4f0b4d3f8a52965f71e0b63c',
      accounts:["a66509890dea9ecdad3244532521c2f332447a54b21656c743a0d7ca2e252831"],
    },
  },
  etherscan: {
    apiKey: "5C38XQQAVKVS3IV4PXGWD7IWE6792I4XMF",
  },
};

export default config;

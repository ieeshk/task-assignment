
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
};

export default config;

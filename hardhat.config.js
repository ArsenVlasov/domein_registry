require("@nomicfoundation/hardhat-toolbox");

const DEFAULT_MNEMONIC = "test test test test test test test test test test test junk";
const MNEMONIC = process.env.MNEMONIC || DEFAULT_MNEMONIC;
const INFURA_API_KEY = process.env.INFURA_API_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "";
const REPORT_GAS = process.env.REPORT_GAS || false;


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
};

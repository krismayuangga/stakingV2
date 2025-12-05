require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 31337
    },
    bscTestnet: {
      url: process.env.BSC_TESTNET_RPC || "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 10000000000 // 10 gwei
    },
    bscMainnet: {
      url: process.env.BSC_MAINNET_RPC || "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 5000000000 // 5 gwei
    }
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSCSCAN_API_KEY || "",
      bsc: process.env.BSCSCAN_API_KEY || ""
    }
  },
  gasReporter: {
    enabled: true,
    currency: "USD"
  }
};





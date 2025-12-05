require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

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
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [] // Add your private keys here for deployment
    },
    bscMainnet: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: [] // Add your private keys here for deployment
    }
  },
  gasReporter: {
    enabled: true,
    currency: "USD"
  }
};





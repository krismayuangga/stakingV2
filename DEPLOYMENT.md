# 🚀 Deployment Guide - OZONE Staking V2

Complete step-by-step deployment guide for BSC Mainnet.

---

## 📋 Pre-Deployment Checklist

### ✅ Requirements

- [ ] Node.js v16+ installed
- [ ] Hardhat configured
- [ ] BSC Mainnet RPC URL
- [ ] Deployer wallet with BNB for gas (~0.5 BNB recommended)
- [ ] OZONE token contract deployed
- [ ] USDT BEP-20 token address (0x55d398326f99059fF775485246999027B3197955)
- [ ] Treasury wallet address prepared
- [ ] Admin wallet prepared

### ✅ Preparation

```bash
# Install dependencies
npm install --save-dev hardhat
npm install @openzeppelin/contracts-upgradeable
npm install @openzeppelin/hardhat-upgrades
npm install @chainlink/contracts
npm install dotenv

# Create .env file
cp .env.example .env
```

### .env Configuration

```bash
# Network
BSC_MAINNET_RPC_URL=https://bsc-dataseed1.binance.org/
BSC_TESTNET_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/

# Deployer
DEPLOYER_PRIVATE_KEY=your_private_key_here

# Contract Addresses
OZONE_TOKEN_ADDRESS=0x...
USDT_TOKEN_ADDRESS=0x55d398326f99059fF775485246999027B3197955
OZONE_MAIN_CONTRACT=0x...

# Wallets
TREASURY_WALLET=0x...
ADMIN_WALLET=0x...

# API Keys
BSCSCAN_API_KEY=your_bscscan_api_key

# Initial Configuration
INITIAL_OZONE_PRICE=1000000000000000000  # 1 OZONE = $1.00 (18 decimals)
PRESALE_SUPPLY=10000000000000000000000000  # 10M OZONE (18 decimals)
```

---

## 🔧 Hardhat Configuration

### hardhat.config.js

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

module.exports = {
    solidity: {
        version: "0.8.20",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        bscTestnet: {
            url: process.env.BSC_TESTNET_RPC_URL,
            chainId: 97,
            accounts: [process.env.DEPLOYER_PRIVATE_KEY]
        },
        bscMainnet: {
            url: process.env.BSC_MAINNET_RPC_URL,
            chainId: 56,
            accounts: [process.env.DEPLOYER_PRIVATE_KEY],
            gasPrice: 3000000000 // 3 Gwei
        }
    },
    etherscan: {
        apiKey: process.env.BSCSCAN_API_KEY
    }
};
```

---

## 📝 Deployment Scripts

### scripts/01-deploy-staking.js

```javascript
const { ethers, upgrades } = require("hardhat");

async function main() {
    console.log("🚀 Deploying OzoneStakingV2...");
    
    const [deployer] = await ethers.getSigners();
    console.log("Deployer:", deployer.address);
    console.log("Balance:", ethers.utils.formatEther(await deployer.getBalance()), "BNB");
    
    // Get contract factory
    const OzoneStakingV2 = await ethers.getContractFactory("OzoneStakingV2");
    
    // Deploy with proxy
    console.log("\n📦 Deploying proxy and implementation...");
    const stakingV2 = await upgrades.deployProxy(
        OzoneStakingV2,
        [
            process.env.OZONE_TOKEN_ADDRESS,
            process.env.USDT_TOKEN_ADDRESS,
            process.env.OZONE_MAIN_CONTRACT,
            process.env.INITIAL_OZONE_PRICE
        ],
        { 
            initializer: 'initialize',
            kind: 'uups'
        }
    );
    
    await stakingV2.deployed();
    
    console.log("\n✅ OzoneStakingV2 deployed!");
    console.log("Proxy address:", stakingV2.address);
    
    // Get implementation address
    const implAddress = await upgrades.erc1967.getImplementationAddress(stakingV2.address);
    console.log("Implementation address:", implAddress);
    
    // Save addresses
    const fs = require('fs');
    const addresses = {
        stakingProxy: stakingV2.address,
        stakingImplementation: implAddress,
        deployedAt: new Date().toISOString(),
        network: network.name
    };
    
    fs.writeFileSync(
        './deployments/staking-addresses.json',
        JSON.stringify(addresses, null, 2)
    );
    
    console.log("\n📝 Addresses saved to deployments/staking-addresses.json");
    
    // Wait for block confirmations
    console.log("\n⏳ Waiting for 5 block confirmations...");
    await stakingV2.deployTransaction.wait(5);
    
    console.log("\n✅ Deployment complete!");
    console.log("\n📋 Next steps:");
    console.log("1. Verify contracts on BSCScan");
    console.log("2. Fund USDT reserves");
    console.log("3. Fund OZONE reserves");
    console.log("4. Deploy Presale contract");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

### scripts/02-deploy-presale.js

```javascript
const { ethers, upgrades } = require("hardhat");
const fs = require('fs');

async function main() {
    console.log("🚀 Deploying OzonePresaleV2...");
    
    const [deployer] = await ethers.getSigners();
    console.log("Deployer:", deployer.address);
    
    // Read staking address
    const stakingAddresses = JSON.parse(
        fs.readFileSync('./deployments/staking-addresses.json')
    );
    
    console.log("Staking contract:", stakingAddresses.stakingProxy);
    
    // Get contract factory
    const OzonePresaleV2 = await ethers.getContractFactory("OzonePresaleV2");
    
    // Deploy with proxy
    console.log("\n📦 Deploying proxy and implementation...");
    const presaleV2 = await upgrades.deployProxy(
        OzonePresaleV2,
        [
            process.env.OZONE_TOKEN_ADDRESS,
            process.env.USDT_TOKEN_ADDRESS,
            stakingAddresses.stakingProxy,
            process.env.TREASURY_WALLET,
            process.env.INITIAL_OZONE_PRICE,
            process.env.PRESALE_SUPPLY
        ],
        {
            initializer: 'initialize',
            kind: 'uups'
        }
    );
    
    await presaleV2.deployed();
    
    console.log("\n✅ OzonePresaleV2 deployed!");
    console.log("Proxy address:", presaleV2.address);
    
    const implAddress = await upgrades.erc1967.getImplementationAddress(presaleV2.address);
    console.log("Implementation address:", implAddress);
    
    // Save addresses
    const addresses = {
        presaleProxy: presaleV2.address,
        presaleImplementation: implAddress,
        stakingContract: stakingAddresses.stakingProxy,
        deployedAt: new Date().toISOString(),
        network: network.name
    };
    
    fs.writeFileSync(
        './deployments/presale-addresses.json',
        JSON.stringify(addresses, null, 2)
    );
    
    console.log("\n📝 Addresses saved to deployments/presale-addresses.json");
    
    // Wait for confirmations
    console.log("\n⏳ Waiting for 5 block confirmations...");
    await presaleV2.deployTransaction.wait(5);
    
    console.log("\n✅ Deployment complete!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

### scripts/03-configure.js

```javascript
const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
    console.log("⚙️ Configuring contracts...");
    
    const [deployer] = await ethers.getSigners();
    
    // Load addresses
    const stakingAddr = JSON.parse(
        fs.readFileSync('./deployments/staking-addresses.json')
    );
    const presaleAddr = JSON.parse(
        fs.readFileSync('./deployments/presale-addresses.json')
    );
    
    // Attach contracts
    const stakingV2 = await ethers.getContractAt("OzoneStakingV2", stakingAddr.stakingProxy);
    const presaleV2 = await ethers.getContractAt("OzonePresaleV2", presaleAddr.presaleProxy);
    const ozoneToken = await ethers.getContractAt("IERC20", process.env.OZONE_TOKEN_ADDRESS);
    const usdtToken = await ethers.getContractAt("IERC20", process.env.USDT_TOKEN_ADDRESS);
    
    console.log("\n1️⃣ Authorizing Presale contract...");
    let tx = await stakingV2.setAuthorizedStakeCreator(presaleAddr.presaleProxy, true);
    await tx.wait();
    console.log("✅ Presale authorized");
    
    console.log("\n2️⃣ Funding StakingV2 USDT reserves...");
    const usdtReserveAmount = ethers.utils.parseUnits("1000000", 6); // 1M USDT
    tx = await usdtToken.approve(stakingAddr.stakingProxy, usdtReserveAmount);
    await tx.wait();
    tx = await stakingV2.fundUSDTReserves(usdtReserveAmount);
    await tx.wait();
    console.log("✅ Funded 1M USDT");
    
    console.log("\n3️⃣ Funding StakingV2 OZONE reserves...");
    const ozoneReserveAmount = ethers.utils.parseEther("5000000"); // 5M OZONE
    tx = await ozoneToken.approve(stakingAddr.stakingProxy, ozoneReserveAmount);
    await tx.wait();
    tx = await stakingV2.fundOzoneReserves(ozoneReserveAmount);
    await tx.wait();
    console.log("✅ Funded 5M OZONE");
    
    console.log("\n4️⃣ Funding Presale supply...");
    const presaleSupply = ethers.utils.parseEther("10000000"); // 10M OZONE
    tx = await ozoneToken.approve(presaleAddr.presaleProxy, presaleSupply);
    await tx.wait();
    tx = await presaleV2.addPresaleSupply(presaleSupply);
    await tx.wait();
    console.log("✅ Funded 10M OZONE presale supply");
    
    console.log("\n✅ Configuration complete!");
    
    // Display stats
    const [activeStakes, usdtDist, ozoneDist, burned, usdtRes, ozoneRes] = 
        await stakingV2.getStakingStats();
    
    console.log("\n📊 Staking Stats:");
    console.log("USDT Reserves:", ethers.utils.formatUnits(usdtRes, 6), "USDT");
    console.log("OZONE Reserves:", ethers.utils.formatEther(ozoneRes), "OZONE");
    
    const presaleStats = await presaleV2.getPresaleStats();
    console.log("\n📊 Presale Stats:");
    console.log("Remaining Supply:", ethers.utils.formatEther(presaleStats.remaining), "OZONE");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

---

## 🔍 Verification Scripts

### scripts/verify-staking.js

```javascript
const { run } = require("hardhat");
const fs = require('fs');

async function main() {
    const addresses = JSON.parse(
        fs.readFileSync('./deployments/staking-addresses.json')
    );
    
    console.log("🔍 Verifying OzoneStakingV2 implementation...");
    
    try {
        await run("verify:verify", {
            address: addresses.stakingImplementation,
            constructorArguments: []
        });
        console.log("✅ Implementation verified!");
    } catch (error) {
        console.log("Error:", error.message);
    }
    
    console.log("\n📝 Proxy address (no verification needed):", addresses.stakingProxy);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

---

## 🚀 Deployment Steps

### Step 1: Testnet Deployment

```bash
# 1. Deploy to testnet first
npx hardhat run scripts/01-deploy-staking.js --network bscTestnet
npx hardhat run scripts/02-deploy-presale.js --network bscTestnet
npx hardhat run scripts/03-configure.js --network bscTestnet

# 2. Test all functions
npx hardhat test --network bscTestnet

# 3. Verify contracts
npx hardhat run scripts/verify-staking.js --network bscTestnet
npx hardhat run scripts/verify-presale.js --network bscTestnet
```

### Step 2: Mainnet Deployment

```bash
# 1. Double-check .env configuration
cat .env

# 2. Check deployer balance
npx hardhat run scripts/check-balance.js --network bscMainnet

# 3. Deploy Staking V2
npx hardhat run scripts/01-deploy-staking.js --network bscMainnet

# 4. Verify Staking
npx hardhat run scripts/verify-staking.js --network bscMainnet

# 5. Deploy Presale V2
npx hardhat run scripts/02-deploy-presale.js --network bscMainnet

# 6. Verify Presale
npx hardhat run scripts/verify-presale.js --network bscMainnet

# 7. Configure integration
npx hardhat run scripts/03-configure.js --network bscMainnet

# 8. Final verification
npx hardhat run scripts/verify-all.js --network bscMainnet
```

---

## 📊 Post-Deployment Verification

### Verify Deployment

```javascript
// scripts/verify-deployment.js
const { ethers } = require("hardhat");

async function main() {
    // Load addresses
    const stakingAddr = require('./deployments/staking-addresses.json');
    const presaleAddr = require('./deployments/presale-addresses.json');
    
    const stakingV2 = await ethers.getContractAt("OzoneStakingV2", stakingAddr.stakingProxy);
    const presaleV2 = await ethers.getContractAt("OzonePresaleV2", presaleAddr.presaleProxy);
    
    console.log("📊 Verification Report\n");
    
    // Check Staking V2
    console.log("=== OzoneStakingV2 ===");
    console.log("Version:", await stakingV2.getVersion());
    console.log("Total Pools:", (await stakingV2.totalPools()).toString());
    
    // Check all pools
    for (let i = 1; i <= 5; i++) {
        const pool = await stakingV2.getPool(i);
        console.log(`\nPool ${i}: ${pool.name}`);
        console.log(`  APY: ${pool.monthlyAPY / 100}%`);
        console.log(`  Active: ${pool.isActive}`);
    }
    
    // Check authorization
    const isAuthorized = await stakingV2.authorizedStakeCreators(presaleAddr.presaleProxy);
    console.log("\n✅ Presale authorized:", isAuthorized);
    
    // Check reserves
    const [,,,, usdtRes, ozoneRes] = await stakingV2.getStakingStats();
    console.log("\n💰 Reserves:");
    console.log("USDT:", ethers.utils.formatUnits(usdtRes, 6));
    console.log("OZONE:", ethers.utils.formatEther(ozoneRes));
    
    // Check Presale V2
    console.log("\n=== OzonePresaleV2 ===");
    console.log("Version:", await presaleV2.getVersion());
    
    const presaleStats = await presaleV2.getPresaleStats();
    console.log("Presale Supply:", ethers.utils.formatEther(presaleStats.remaining), "OZONE");
    
    const price = await presaleV2.getCurrentPrice();
    console.log("Current Price: $" + ethers.utils.formatEther(price));
    
    console.log("\n✅ All checks passed!");
}

main();
```

---

## 🔐 Security Checklist

### Pre-Launch

- [ ] All contracts verified on BSCScan
- [ ] Multi-sig wallet setup for owner (recommended)
- [ ] Time-lock on admin functions (optional)
- [ ] Bug bounty program announced
- [ ] Emergency pause tested
- [ ] Upgrade process tested on testnet
- [ ] Reserve levels monitored
- [ ] Price oracle working correctly

### Post-Launch

- [ ] Monitor transactions 24/7
- [ ] Set up alerts for low reserves
- [ ] Regular price updates (if manual)
- [ ] Weekly reserve checks
- [ ] Monthly security reviews
- [ ] User support ready

---

## 🆘 Emergency Procedures

### If Critical Bug Found

```javascript
// 1. Pause contracts immediately
await stakingV2.pause();
await presaleV2.pause();

// 2. Assess impact
// 3. Fix bug in new implementation
// 4. Deploy new implementation
// 5. Upgrade via UUPS
await stakingV2.upgradeTo(newImplementationAddress);

// 6. Test extensively
// 7. Unpause
await stakingV2.unpause();
```

### If Reserves Low

```javascript
// Monitor script (run continuously)
setInterval(async () => {
    const [,,,, usdtRes, ozoneRes] = await stakingV2.getStakingStats();
    
    const minUSDT = ethers.utils.parseUnits("100000", 6); // 100k threshold
    const minOZONE = ethers.utils.parseEther("1000000"); // 1M threshold
    
    if (usdtRes.lt(minUSDT)) {
        console.warn("⚠️ USDT reserves below threshold!");
        // Send alert
    }
    
    if (ozoneRes.lt(minOZONE)) {
        console.warn("⚠️ OZONE reserves below threshold!");
        // Send alert
    }
}, 60000); // Check every minute
```

---

## 📞 Support Contacts

**Deployment Issues**: dev@ozone.com  
**Security Concerns**: security@ozone.com  
**Emergency**: telegram.me/ozoneadmin

---

**Last Updated**: December 2, 2025  
**Network**: BSC Mainnet  
**Chain ID**: 56

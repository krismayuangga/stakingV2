# 🚀 Panduan Integrasi - OzoneStakingV2

Dokumentasi lengkap untuk Backend & Frontend Developer

---

## 📋 Daftar Isi

- [Overview](#-overview)
- [Perbedaan dengan Contract Lama](#-perbedaan-dengan-contract-lama)
- [Setup & Deployment](#-setup--deployment)
- [Backend Integration](#-backend-integration)
- [Frontend Integration](#-frontend-integration)
- [Price Update Service](#-price-update-service)
- [Testing](#-testing)
- [Migration dari Contract Lama](#-migration-dari-contract-lama)

---

## 🎯 Overview

### **Apa itu OzoneStakingV2?**

Contract baru yang **menggabungkan Presale + Staking dalam 1 contract**:

**Contract Lama (2 contract terpisah):**
```
presale.sol → User beli OZONE dengan USDT
     ↓
User terima OZONE ke wallet
     ↓
staking.sol → User stake OZONE manual
```

**Contract Baru (1 contract terintegrasi):**
```
OzoneStakingV2 → User beli OZONE + langsung stake (1 transaksi!)
              → Atau user stake OZONE yang sudah dimiliki
```

### **Fitur Utama:**

1. **Buy & Stake** - Beli OZONE langsung auto-stake (1 klik!)
2. **Manual Stake** - Stake OZONE yang sudah dimiliki
3. **5 Pool Tiers** - LimoX A/B/C (6-8% APY), SaproX A/B (9-10% APY)
4. **USDT Rewards Only** - Reward hanya USDT, bukan OZONE
5. **Auto-Burn** - OZONE principal burn setelah durasi habis
6. **Upgradeable** - UUPS pattern, bisa upgrade tanpa migrasi

---

## 🔄 Perbedaan dengan Contract Lama

| Aspek | Contract Lama | OzoneStakingV2 (Baru) |
|-------|---------------|----------------------|
| **Jumlah Contract** | 2 terpisah (presale + staking) | 1 terintegrasi |
| **User Flow** | Beli → Terima OZONE → Stake manual | Beli → Auto-stake (1 transaksi) |
| **OZONE Location** | User wallet → Contract | Langsung di contract |
| **Rewards** | OZONE + USDT | USDT only |
| **Pool Selection** | Auto (by amount) | Manual pilih pool |
| **Tax Handling** | Terpisah | Terintegrasi (1% USDT + 1% OZONE) |
| **Upgradeable** | ❌ No | ✅ Yes (UUPS proxy) |

---

## 🛠 Setup & Deployment

### **Prerequisites:**

```bash
Node.js: v18+
Hardhat: latest
OpenZeppelin Contracts Upgradeable: v5.0+
```

### **1. Install Dependencies**

```bash
npm install --save-dev hardhat
npm install @openzeppelin/contracts-upgradeable
npm install @openzeppelin/hardhat-upgrades
npm install ethers
```

### **2. Deploy Script**

```javascript
// scripts/deploy-stakingV2.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    console.log("Deploying OzoneStakingV2...");
    
    // Addresses (ganti dengan address Anda)
    const OZONE_TOKEN = "0xYourOzoneTokenAddress";
    const USDT_TOKEN = "0x55d398326f99059fF775485246999027B3197955"; // USDT BSC
    const OZONE_CONTRACT = "0xYourOzoneMainContractAddress";
    const TREASURY_WALLET = "0xYourTreasuryWalletAddress";
    const TAX_WALLET = "0xYourTaxWalletAddress";
    
    // Parameters
    const INITIAL_OZONE_PRICE = ethers.utils.parseEther("91"); // $91 per OZONE
    const PRESALE_SUPPLY = ethers.utils.parseEther("100000000"); // 100M OZONE
    
    // Deploy
    const StakingV2 = await ethers.getContractFactory("OzoneStakingV2");
    const stakingV2 = await upgrades.deployProxy(StakingV2, [
        OZONE_TOKEN,
        USDT_TOKEN,
        OZONE_CONTRACT,
        INITIAL_OZONE_PRICE,
        TREASURY_WALLET,
        TAX_WALLET,
        PRESALE_SUPPLY
    ], { kind: 'uups' });
    
    await stakingV2.deployed();
    
    console.log("OzoneStakingV2 deployed to:", stakingV2.address);
    console.log("Implementation at:", await upgrades.erc1967.getImplementationAddress(stakingV2.address));
    
    // Post-deployment setup
    console.log("\n⚠️ IMPORTANT POST-DEPLOYMENT STEPS:");
    console.log("1. Transfer OZONE presale supply to contract:");
    console.log(`   ozoneToken.transfer("${stakingV2.address}", "${PRESALE_SUPPLY}")`);
    console.log("\n2. Set contract as tax-exempt in OZONE token:");
    console.log(`   ozoneToken.setTaxExempt("${stakingV2.address}", true)`);
    console.log("\n3. Fund USDT reserves for rewards:");
    console.log(`   Call fundUSDTReserves() with initial USDT`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

### **3. Deploy ke BSC Testnet/Mainnet**

```bash
# Testnet
npx hardhat run scripts/deploy-stakingV2.js --network bscTestnet

# Mainnet (production)
npx hardhat run scripts/deploy-stakingV2.js --network bscMainnet
```

### **4. Verify Contract**

```bash
npx hardhat verify --network bscMainnet <PROXY_ADDRESS>
```

### **5. Post-Deployment Setup**

**CRITICAL - Harus dilakukan setelah deploy:**

```javascript
// 1. Transfer OZONE untuk presale supply
await ozoneToken.transfer(stakingV2Address, ethers.utils.parseEther("100000000"));

// 2. Set contract sebagai tax-exempt di OZONE token
await ozoneToken.setTaxExempt(stakingV2Address, true);

// 3. Fund USDT reserves untuk rewards
await usdtToken.approve(stakingV2Address, ethers.utils.parseEther("1000000"));
await stakingV2.fundUSDTReserves(ethers.utils.parseEther("1000000"));

// 4. Activate presale
await stakingV2.setPresaleActive(true);

// 5. Setup price updater (untuk backend)
await stakingV2.setOzonePrice(ethers.utils.parseEther("91")); // Set initial price
```

---

## 💻 Backend Integration

### **Setup**

```javascript
// backend/config/contracts.js
const ethers = require('ethers');

const STAKING_V2_ADDRESS = "0xYourStakingV2Address";
const STAKING_V2_ABI = require('./abis/OzoneStakingV2.json');

const provider = new ethers.providers.JsonRpcProvider(
    process.env.BSC_RPC_URL || 'https://bsc-dataseed1.binance.org/'
);

const adminWallet = new ethers.Wallet(process.env.ADMIN_PRIVATE_KEY, provider);

const stakingV2Contract = new ethers.Contract(
    STAKING_V2_ADDRESS,
    STAKING_V2_ABI,
    adminWallet
);

module.exports = { stakingV2Contract, provider };
```

### **1. Price Update Service**

**PENTING:** Backend harus update price secara berkala!

```javascript
// backend/services/priceUpdater.js
const axios = require('axios');
const { stakingV2Contract } = require('../config/contracts');

class PriceUpdaterService {
    constructor() {
        this.updateInterval = 2 * 60 * 1000; // 2 minutes
        this.minPriceChange = 0.005; // 0.5% minimum change
        this.lastPrice = null;
    }
    
    /**
     * Fetch OZONE price dari DigiFinex
     */
    async fetchDigiFinexPrice() {
        try {
            const response = await axios.get('https://openapi.digifinex.com/v3/ticker', {
                params: { symbol: 'ozone_usdt' },
                timeout: 10000
            });
            
            if (!response.data || !response.data.ticker || !response.data.ticker[0]) {
                throw new Error('Invalid DigiFinex response');
            }
            
            const price = parseFloat(response.data.ticker[0].last);
            
            if (isNaN(price) || price <= 0) {
                throw new Error('Invalid price value');
            }
            
            console.log(`✅ DigiFinex OZONE price: $${price}`);
            return price;
            
        } catch (error) {
            console.error('❌ Error fetching DigiFinex price:', error.message);
            return null;
        }
    }
    
    /**
     * Update price on-chain
     */
    async updatePriceOnChain(price) {
        try {
            // Convert to 18 decimals
            const priceWei = ethers.utils.parseEther(price.toString());
            
            // Get current on-chain price
            const currentPrice = await stakingV2Contract.ozonePrice();
            const currentPriceFloat = parseFloat(ethers.utils.formatEther(currentPrice));
            
            // Check if price changed significantly
            if (this.lastPrice) {
                const priceChange = Math.abs((price - currentPriceFloat) / currentPriceFloat);
                
                if (priceChange < this.minPriceChange) {
                    console.log(`⏭️  Price change ${(priceChange * 100).toFixed(2)}% < ${(this.minPriceChange * 100)}%, skipping update`);
                    return false;
                }
            }
            
            console.log(`📤 Updating on-chain price: $${currentPriceFloat} → $${price}`);
            
            // Send transaction
            const tx = await stakingV2Contract.setOzonePrice(priceWei, {
                gasLimit: 100000,
                gasPrice: await provider.getGasPrice()
            });
            
            console.log(`📡 Transaction sent: ${tx.hash}`);
            
            const receipt = await tx.wait();
            
            console.log(`✅ Price updated successfully in block ${receipt.blockNumber}`);
            console.log(`⛽ Gas used: ${receipt.gasUsed.toString()}`);
            
            this.lastPrice = price;
            
            return true;
            
        } catch (error) {
            console.error('❌ Error updating price on-chain:', error.message);
            
            // Log specific error types
            if (error.code === 'INSUFFICIENT_FUNDS') {
                console.error('⚠️  Insufficient BNB for gas!');
            } else if (error.code === 'NONCE_EXPIRED') {
                console.error('⚠️  Nonce issue, retry...');
            }
            
            return false;
        }
    }
    
    /**
     * Main update loop
     */
    async start() {
        console.log('🚀 OZONE Price Updater Service Started');
        console.log(`⏱️  Update interval: ${this.updateInterval / 1000} seconds`);
        console.log(`📊 Minimum price change: ${this.minPriceChange * 100}%`);
        
        // Initial update
        await this.runUpdate();
        
        // Set interval
        setInterval(() => this.runUpdate(), this.updateInterval);
    }
    
    async runUpdate() {
        const price = await this.fetchDigiFinexPrice();
        
        if (price) {
            await this.updatePriceOnChain(price);
        }
    }
}

// Export singleton
const priceUpdater = new PriceUpdaterService();
module.exports = priceUpdater;
```

**Start Service:**

```javascript
// backend/index.js atau app.js
const priceUpdater = require('./services/priceUpdater');

// Start price updater
priceUpdater.start();

// ... rest of your backend code
```

### **2. API Endpoints (Optional)**

Jika mau expose data ke frontend:

```javascript
// backend/routes/staking.js
const express = require('express');
const router = express.Router();
const { stakingV2Contract } = require('../config/contracts');

/**
 * GET /api/staking/price
 * Get current OZONE price
 */
router.get('/price', async (req, res) => {
    try {
        const priceWei = await stakingV2Contract.ozonePrice();
        const price = parseFloat(ethers.utils.formatEther(priceWei));
        
        res.json({
            success: true,
            data: {
                price: price,
                priceWei: priceWei.toString(),
                lastUpdate: await stakingV2Contract.lastPriceUpdate()
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/staking/pools
 * Get all pool information
 */
router.get('/pools', async (req, res) => {
    try {
        const totalPools = await stakingV2Contract.nextPoolId();
        const pools = [];
        
        for (let i = 1; i < totalPools; i++) {
            const pool = await stakingV2Contract.pools(i);
            pools.push({
                id: i,
                name: pool.name,
                monthlyAPY: pool.monthlyAPY / 100, // Convert from basis points
                minStake: ethers.utils.formatEther(pool.minStakeUSDT),
                maxStake: pool.maxStakeUSDT.gt(0) ? ethers.utils.formatEther(pool.maxStakeUSDT) : 'Unlimited',
                totalStaked: ethers.utils.formatEther(pool.totalStaked),
                isActive: pool.isActive
            });
        }
        
        res.json({ success: true, data: pools });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/staking/user/:address
 * Get user stakes
 */
router.get('/user/:address', async (req, res) => {
    try {
        const { address } = req.params;
        
        if (!ethers.utils.isAddress(address)) {
            return res.status(400).json({ success: false, error: 'Invalid address' });
        }
        
        const stakes = await stakingV2Contract.getUserStakes(address);
        
        const formattedStakes = stakes.map((stake, index) => ({
            index: index,
            amount: ethers.utils.formatEther(stake.amount),
            originalAmount: ethers.utils.formatEther(stake.originalAmount),
            usdtValue: ethers.utils.formatEther(stake.usdtValueAtStake),
            poolId: stake.poolId.toString(),
            lockedAPY: stake.lockedAPY / 100,
            startTime: new Date(stake.startTime * 1000).toISOString(),
            nextClaimTime: new Date(stake.nextClaimTime * 1000).toISOString(),
            totalClaimed: ethers.utils.formatEther(stake.totalClaimedReward),
            isActive: stake.isActive,
            isBurned: stake.isBurned,
            isFromPresale: stake.isFromPresale
        }));
        
        res.json({ success: true, data: formattedStakes });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
```

---

## 🎨 Frontend Integration

### **Setup Web3**

```javascript
// frontend/utils/web3.js
import { ethers } from 'ethers';
import StakingV2ABI from './abis/OzoneStakingV2.json';

const STAKING_V2_ADDRESS = "0xYourStakingV2Address";
const USDT_ADDRESS = "0x55d398326f99059fF775485246999027B3197955";
const OZONE_ADDRESS = "0xYourOzoneTokenAddress";

export const getProvider = () => {
    if (window.ethereum) {
        return new ethers.providers.Web3Provider(window.ethereum);
    }
    throw new Error('Please install MetaMask');
};

export const getStakingV2Contract = (signer) => {
    return new ethers.Contract(STAKING_V2_ADDRESS, StakingV2ABI, signer);
};

export const getUSDTContract = (signer) => {
    const ABI = ['function approve(address spender, uint256 amount) returns (bool)'];
    return new ethers.Contract(USDT_ADDRESS, ABI, signer);
};

export const getOZONEContract = (signer) => {
    const ABI = ['function approve(address spender, uint256 amount) returns (bool)'];
    return new ethers.Contract(OZONE_ADDRESS, ABI, signer);
};
```

### **1. Buy & Stake (Presale)**

```javascript
// frontend/components/BuyAndStake.jsx
import { useState } from 'react';
import { ethers } from 'ethers';
import { getProvider, getStakingV2Contract, getUSDTContract } from '../utils/web3';

function BuyAndStake() {
    const [poolId, setPoolId] = useState(1);
    const [usdtAmount, setUsdtAmount] = useState('');
    const [loading, setLoading] = useState(false);
    
    const handleBuyAndStake = async () => {
        try {
            setLoading(true);
            
            const provider = getProvider();
            const signer = provider.getSigner();
            const stakingV2 = getStakingV2Contract(signer);
            const usdt = getUSDTContract(signer);
            
            // Parse amount
            const baseAmount = ethers.utils.parseEther(usdtAmount); // USDT 18 decimals
            
            // Calculate total cost (base + 1% tax)
            const taxAmount = baseAmount.mul(100).div(10000); // 1%
            const totalCost = baseAmount.add(taxAmount);
            
            console.log('Base amount:', ethers.utils.formatEther(baseAmount), 'USDT');
            console.log('Tax (1%):', ethers.utils.formatEther(taxAmount), 'USDT');
            console.log('Total cost:', ethers.utils.formatEther(totalCost), 'USDT');
            
            // Step 1: Approve USDT (total cost)
            console.log('Approving USDT...');
            const approveTx = await usdt.approve(stakingV2.address, totalCost);
            await approveTx.wait();
            console.log('✅ USDT approved');
            
            // Step 2: Buy and stake
            console.log('Buying and staking...');
            const tx = await stakingV2.buyAndStake(poolId, baseAmount, {
                gasLimit: 500000
            });
            
            console.log('Transaction sent:', tx.hash);
            const receipt = await tx.wait();
            console.log('✅ Transaction confirmed!');
            
            // Show success message
            alert('Successfully bought and staked OZONE!');
            
            // Reset form
            setUsdtAmount('');
            
        } catch (error) {
            console.error('Error:', error);
            alert('Error: ' + error.message);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div className="buy-stake-container">
            <h2>Buy & Stake OZONE</h2>
            
            <div className="form-group">
                <label>Select Pool:</label>
                <select value={poolId} onChange={(e) => setPoolId(parseInt(e.target.value))}>
                    <option value={1}>LimoX Pool A (6% APY)</option>
                    <option value={2}>LimoX Pool B (7% APY)</option>
                    <option value={3}>LimoX Pool C (8% APY)</option>
                    <option value={4}>SaproX Pool A (9% APY)</option>
                    <option value={5}>SaproX Pool B (10% APY)</option>
                </select>
            </div>
            
            <div className="form-group">
                <label>USDT Amount:</label>
                <input 
                    type="number"
                    value={usdtAmount}
                    onChange={(e) => setUsdtAmount(e.target.value)}
                    placeholder="Enter USDT amount"
                />
                <small>+ 1% platform fee will be added</small>
            </div>
            
            <button onClick={handleBuyAndStake} disabled={loading}>
                {loading ? 'Processing...' : 'Buy & Stake'}
            </button>
        </div>
    );
}

export default BuyAndStake;
```

### **2. Manual Stake**

```javascript
// frontend/components/ManualStake.jsx
import { useState } from 'react';
import { ethers } from 'ethers';
import { getProvider, getStakingV2Contract, getOZONEContract } from '../utils/web3';

function ManualStake() {
    const [poolId, setPoolId] = useState(1);
    const [ozoneAmount, setOzoneAmount] = useState('');
    const [loading, setLoading] = useState(false);
    
    const handleStake = async () => {
        try {
            setLoading(true);
            
            const provider = getProvider();
            const signer = provider.getSigner();
            const stakingV2 = getStakingV2Contract(signer);
            const ozone = getOZONEContract(signer);
            
            // Parse amount (18 decimals)
            const amount = ethers.utils.parseEther(ozoneAmount);
            
            console.log('Staking amount:', ethers.utils.formatEther(amount), 'OZONE');
            
            // Step 1: Approve OZONE
            console.log('Approving OZONE...');
            const approveTx = await ozone.approve(stakingV2.address, amount);
            await approveTx.wait();
            console.log('✅ OZONE approved');
            
            // Step 2: Stake
            console.log('Staking...');
            const tx = await stakingV2.stake(poolId, amount, {
                gasLimit: 400000
            });
            
            console.log('Transaction sent:', tx.hash);
            const receipt = await tx.wait();
            console.log('✅ Staked successfully!');
            
            alert('Successfully staked OZONE!');
            setOzoneAmount('');
            
        } catch (error) {
            console.error('Error:', error);
            alert('Error: ' + error.message);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div className="manual-stake-container">
            <h2>Stake OZONE</h2>
            
            <div className="form-group">
                <label>Select Pool:</label>
                <select value={poolId} onChange={(e) => setPoolId(parseInt(e.target.value))}>
                    <option value={1}>LimoX Pool A (6% APY)</option>
                    <option value={2}>LimoX Pool B (7% APY)</option>
                    <option value={3}>LimoX Pool C (8% APY)</option>
                    <option value={4}>SaproX Pool A (9% APY)</option>
                    <option value={5}>SaproX Pool B (10% APY)</option>
                </select>
            </div>
            
            <div className="form-group">
                <label>OZONE Amount:</label>
                <input 
                    type="number"
                    value={ozoneAmount}
                    onChange={(e) => setOzoneAmount(e.target.value)}
                    placeholder="Enter OZONE amount"
                />
                <small>⚠️ Note: 1% transfer tax will be deducted automatically</small>
            </div>
            
            <button onClick={handleStake} disabled={loading}>
                {loading ? 'Processing...' : 'Stake'}
            </button>
        </div>
    );
}

export default ManualStake;
```

### **3. Claim Rewards**

```javascript
// frontend/components/ClaimRewards.jsx
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { getProvider, getStakingV2Contract } from '../utils/web3';

function ClaimRewards() {
    const [stakes, setStakes] = useState([]);
    const [loading, setLoading] = useState(false);
    
    useEffect(() => {
        loadUserStakes();
    }, []);
    
    const loadUserStakes = async () => {
        try {
            const provider = getProvider();
            const signer = provider.getSigner();
            const address = await signer.getAddress();
            const stakingV2 = getStakingV2Contract(signer);
            
            const userStakes = await stakingV2.getUserStakes(address);
            setStakes(userStakes);
            
        } catch (error) {
            console.error('Error loading stakes:', error);
        }
    };
    
    const handleClaim = async (stakeIndex) => {
        try {
            setLoading(true);
            
            const provider = getProvider();
            const signer = provider.getSigner();
            const stakingV2 = getStakingV2Contract(signer);
            
            console.log('Claiming rewards for stake', stakeIndex);
            
            const tx = await stakingV2.claimRewards(stakeIndex, {
                gasLimit: 300000
            });
            
            console.log('Transaction sent:', tx.hash);
            await tx.wait();
            console.log('✅ Rewards claimed!');
            
            alert('Successfully claimed rewards!');
            
            // Reload stakes
            await loadUserStakes();
            
        } catch (error) {
            console.error('Error:', error);
            alert('Error: ' + error.message);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div className="claim-rewards-container">
            <h2>My Stakes</h2>
            
            {stakes.map((stake, index) => (
                <div key={index} className="stake-card">
                    <h3>Stake #{index + 1}</h3>
                    <p>Amount: {ethers.utils.formatEther(stake.amount)} OZONE</p>
                    <p>USDT Value: ${ethers.utils.formatEther(stake.usdtValueAtStake)}</p>
                    <p>APY: {stake.lockedAPY / 100}%</p>
                    <p>Claimed: ${ethers.utils.formatEther(stake.totalClaimedReward)} USDT</p>
                    <p>Status: {stake.isActive ? 'Active' : 'Inactive'}</p>
                    
                    {stake.isActive && (
                        <button 
                            onClick={() => handleClaim(index)}
                            disabled={loading}
                        >
                            {loading ? 'Claiming...' : 'Claim Rewards'}
                        </button>
                    )}
                </div>
            ))}
            
            {stakes.length === 0 && <p>No stakes found</p>}
        </div>
    );
}

export default ClaimRewards;
```

---

## 📊 Testing

### **Test Script**

```javascript
// test/stakingV2.test.js
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("OzoneStakingV2", function () {
    let stakingV2, ozoneToken, usdtToken;
    let owner, user1, treasury, taxWallet;
    
    beforeEach(async function () {
        [owner, user1, treasury, taxWallet] = await ethers.getSigners();
        
        // Deploy mock tokens
        const ERC20 = await ethers.getContractFactory("MockERC20");
        ozoneToken = await ERC20.deploy("OZONE", "OZO", 18);
        usdtToken = await ERC20.deploy("USDT", "USDT", 18);
        
        // Deploy StakingV2
        const StakingV2 = await ethers.getContractFactory("OzoneStakingV2");
        stakingV2 = await upgrades.deployProxy(StakingV2, [
            ozoneToken.address,
            usdtToken.address,
            ozoneToken.address, // Using OZONE as contract for testing
            ethers.utils.parseEther("91"), // $91 price
            treasury.address,
            taxWallet.address,
            ethers.utils.parseEther("100000000")
        ], { kind: 'uups' });
        
        // Setup
        await ozoneToken.transfer(stakingV2.address, ethers.utils.parseEther("100000000"));
        await usdtToken.transfer(user1.address, ethers.utils.parseEther("10000"));
    });
    
    it("Should allow buy and stake", async function () {
        const usdtAmount = ethers.utils.parseEther("1000");
        const taxAmount = usdtAmount.mul(100).div(10000);
        const totalCost = usdtAmount.add(taxAmount);
        
        // Approve
        await usdtToken.connect(user1).approve(stakingV2.address, totalCost);
        
        // Buy and stake
        await expect(stakingV2.connect(user1).buyAndStake(1, usdtAmount))
            .to.emit(stakingV2, "PresalePurchase");
        
        // Check user stakes
        const stakes = await stakingV2.getUserStakes(user1.address);
        expect(stakes.length).to.equal(1);
    });
    
    // Add more tests...
});
```

---

## 🔄 Migration dari Contract Lama

### **Langkah Migration:**

1. **Deploy Contract Baru** ✅
2. **Setup Post-Deployment** ✅
3. **Pause Contract Lama** (presale & staking)
4. **Update Frontend** (arahkan ke contract baru)
5. **Update Backend** (add price updater service)
6. **Testing di Testnet**
7. **Deploy ke Mainnet**
8. **Announce to Users**

### **Backward Compatibility:**

Contract lama tetap berjalan untuk:
- User yang sudah stake di contract lama
- Claim rewards yang belum di-claim
- Unstake (jika diperlukan)

Contract baru untuk:
- Presale baru
- Staking baru
- Future users

---

## 📚 Resources

- **Contract Source:** `OzoneStakingV2.sol`
- **ABI:** Export dari Hardhat compilation
- **Docs:** README_ID.md, TECHNICAL_ID.md
- **Tax Guide:** TAX_IMPLEMENTATION.md

---

**Butuh bantuan?** Check dokumentasi lengkap atau hubungi development team! 🚀

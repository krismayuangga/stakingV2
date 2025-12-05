# 🚀 PANDUAN LENGKAP - OZONE Staking V2

**Platform Presale & Staking Terintegrasi untuk Buyer Baru**

Version: 2.0.0  
Last Updated: 5 Desember 2025  
Network: Binance Smart Chain (BSC)

---

## 📋 Daftar Isi

1. [Overview & Konsep](#1-overview--konsep)
2. [Fitur Utama](#2-fitur-utama)
3. [Sistem Pool & APY](#3-sistem-pool--apy)
4. [Tax & Fee System](#4-tax--fee-system)
5. [Cara Kerja](#5-cara-kerja)
6. [Setup & Deployment](#6-setup--deployment)
7. [Backend Integration](#7-backend-integration)
8. [Frontend Integration](#8-frontend-integration)
9. [Admin Operations](#9-admin-operations)
10. [Security & Audit](#10-security--audit)

---

## 1. Overview & Konsep

### 🎯 Apa itu OzoneStakingV2?

Contract smart contract **KHUSUS UNTUK BUYER BARU** yang menggabungkan presale + staking dalam 1 transaksi.

### ⚠️ PENTING: Untuk Siapa Contract Ini?

**✅ UNTUK: Buyer Baru (Belum Punya OZONE)**
- Beli OZONE dengan USDT
- Langsung auto-stake
- Pakai harga real-time dari DigiFinex (~$91)

**❌ TIDAK UNTUK: Holder Lama (Sudah Punya OZONE)**
- Jangan stake di contract ini!
- Gunakan contract staking LAMA
- Ratio 1:1 ($1 per OZONE)

### 💰 Kenapa Manual Staking DISABLED?

**Analisis Kerugian Finansial:**

```
Skenario: User lama stake 10,000 OZONE (beli di presale $1)

Jika manual staking dibolehkan:
- Harga beli lama: $1 per OZONE
- Harga sekarang: $91 per OZONE (91x!)
- Nilai USDT: 10,000 × $91 = $910,000 😱
- Reward bulanan (9%): $81,900 USDT
- Reward tahunan: $982,800 USDT

CONTRACT RUGI $972,800 untuk investasi $10,000!
```

**Solusi:**
- ✅ Buyer baru → Contract BARU (harga $91)
- ✅ Holder lama → Contract LAMA (harga $1)

---

## 2. Fitur Utama

### 🛒 Buy & Stake (Satu-satunya Cara)

- Beli OZONE dengan USDT
- Langsung masuk staking (1 transaksi)
- OZONE tidak pernah masuk wallet user (anti-dump)
- Pilih pool sendiri (5 tier tersedia)

### 💎 USDT-Only Rewards

- Semua reward dalam bentuk USDT stablecoin
- Tidak ada opsi reward OZONE
- Predictable value, no volatility

### 🏆 5 Pool Tiers

| Pool | USDT Range | APY/Bulan | Durasi |
|------|------------|-----------|--------|
| LimoX A | $100-1K | 6% | 50 bulan |
| LimoX B | $1K-3K | 7% | ~43 bulan |
| LimoX C | $3K-5K | 8% | 37.5 bulan |
| SaproX A | $5K-10K | 9% | ~33 bulan |
| SaproX B | $10K+ | 10% | 30 bulan |

### 🔥 Auto-Burn Mechanism

- Principal OZONE di-burn otomatis setelah durasi habis
- Deflationary tokenomics
- User tetap dapat 100% USDT rewards

### 🔄 Upgradeable (UUPS)

- Bisa upgrade tanpa migrasi data
- Fix bugs tanpa deploy ulang
- User funds tetap aman

---

## 3. Sistem Pool & APY

### Perhitungan Reward

**Formula:**
```
Daily Reward = (USDT Value × Monthly APY%) / 30 days
Monthly Reward = Daily Reward × 30
Total Duration = Pool duration months
```

**Contoh: Investment $5,000 di SaproX Pool A**

```
Input:
- USDT Amount: $5,000
- OZONE Price: $91
- Pool: SaproX Pool A (9% APY, 360 days)

Perhitungan:
1. OZONE Received: $5,000 / $91 = 54.95 OZONE
2. Platform Fee (1%): $50 USDT → Tax Wallet
3. Net to Treasury: $4,950 USDT

Rewards:
- Monthly APY: 9%
- Monthly Reward: $5,000 × 9% = $450 USDT
- Daily Reward: $450 / 30 = $15 USDT/day
- Total Duration: 360 days (12 months)
- Total Rewards: $450 × 12 = $5,400 USDT

Hasil Akhir (setelah 360 hari):
✅ Total USDT earned: $5,400
✅ Principal OZONE: 54.95 OZONE burned 🔥
✅ Net Profit: $400 (8% ROI)
```

---

## 4. Tax & Fee System

### 💳 Platform Fee - 1% USDT

**Saat buyAndStake():**

```
User bayar USDT:
├─ Base Amount: $5,000 → Treasury Wallet (99%)
├─ Platform Fee (1%): $50 → Tax Wallet
└─ Total Cost: $5,050 USDT

OZONE yang didapat:
- Calculated from: $5,000 (base only)
- Amount: $5,000 / $91 = 54.95 OZONE
- Staked: 54.95 OZONE

Rewards:
- Based on: $5,000 (base amount)
- Not affected by 1% fee
```

**⚠️ Penting:**
- User harus approve **total cost** ($5,050)
- OZONE dihitung dari **base price** ($5,000)
- Rewards dari **base price** ($5,000)

### 📊 Tax Breakdown

| Komponen | Jumlah | Tujuan |
|----------|--------|--------|
| Base Price | $5,000 | Treasury Wallet |
| Platform Fee (1%) | $50 | Tax Wallet |
| **Total User Bayar** | **$5,050** | - |
| OZONE Received | 54.95 | Staked (tidak ke wallet) |
| USDT for Rewards | $5,000 | Basis perhitungan |

---

## 5. Cara Kerja

### Flow Buy & Stake

```
┌─────────────┐
│    USER     │
└──────┬──────┘
       │
       │ 1. Approve $5,050 USDT
       ↓
┌─────────────────────┐
│  OzoneStakingV2     │
├─────────────────────┤
│ 2. Transfer USDT:   │
│    $5,000 → Treasury│
│    $50 → Tax Wallet │
│                     │
│ 3. Calculate OZONE: │
│    54.95 OZONE      │
│                     │
│ 4. Create Stake:    │
│    Pool: SaproX A   │
│    Amount: 54.95    │
│    USDT: $5,000     │
│    APY: 9%          │
└─────────────────────┘
       │
       │ 5. Emit Events
       ↓
┌─────────────┐
│ STAKED! ✅  │
│ Start Earning│
└─────────────┘
```

### Flow Claim Rewards

```
┌─────────────┐
│    USER     │
└──────┬──────┘
       │
       │ 1. Call claimRewards(0)
       ↓
┌─────────────────────┐
│  OzoneStakingV2     │
├─────────────────────┤
│ 2. Calculate:       │
│    Days elapsed: 30 │
│    Daily: $15       │
│    Total: $450      │
│                     │
│ 3. Check Reserves   │
│                     │
│ 4. Transfer USDT    │
│    $450 → User      │
└─────────────────────┘
       │
       │ 5. Update lastClaimTime
       ↓
┌─────────────┐
│ CLAIMED! ✅ │
│ $450 USDT   │
└─────────────┘
```

---

## 6. Setup & Deployment

### Prerequisites

```bash
Node.js: v18+
Hardhat: latest
NPM packages:
  - @openzeppelin/contracts-upgradeable
  - @openzeppelin/hardhat-upgrades
  - ethers
```

### Install Dependencies

```bash
npm install --save-dev hardhat
npm install @openzeppelin/contracts-upgradeable
npm install @openzeppelin/hardhat-upgrades
npm install ethers
```

### Deploy Script

```javascript
// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    console.log("Deploying OzoneStakingV2...");
    
    // Addresses
    const OZONE_TOKEN = "0xYourOzoneTokenAddress";
    const USDT_TOKEN = "0x55d398326f99059fF775485246999027B3197955"; // USDT BSC
    const OZONE_CONTRACT = "0xYourOzoneMainContractAddress";
    const TREASURY = "0xYourTreasuryAddress";
    const TAX_WALLET = "0xYourTaxWalletAddress";
    
    // Parameters
    const INITIAL_PRICE = ethers.utils.parseEther("91"); // $91
    const PRESALE_SUPPLY = ethers.utils.parseEther("100000000"); // 100M
    
    // Deploy
    const StakingV2 = await ethers.getContractFactory("OzoneStakingV2");
    const stakingV2 = await upgrades.deployProxy(StakingV2, [
        OZONE_TOKEN,
        USDT_TOKEN,
        OZONE_CONTRACT,
        INITIAL_PRICE,
        TREASURY,
        TAX_WALLET,
        PRESALE_SUPPLY
    ], { kind: 'uups' });
    
    await stakingV2.deployed();
    
    console.log("✅ Deployed to:", stakingV2.address);
    console.log("📝 Implementation:", await upgrades.erc1967.getImplementationAddress(stakingV2.address));
}

main().catch(console.error);
```

### Deploy ke BSC

```bash
# Testnet
npx hardhat run scripts/deploy.js --network bscTestnet

# Mainnet
npx hardhat run scripts/deploy.js --network bscMainnet
```

### Post-Deployment Setup

**CRITICAL - Harus dilakukan setelah deploy:**

```javascript
// 1. Transfer OZONE untuk presale supply
await ozoneToken.transfer(
    stakingV2Address, 
    ethers.utils.parseEther("100000000")
);

// 2. Set contract tax-exempt di OZONE token
await ozoneToken.setTaxExempt(stakingV2Address, true);

// 3. Fund USDT reserves untuk rewards
await usdtToken.approve(stakingV2Address, ethers.utils.parseEther("1000000"));
await stakingV2.fundUSDTReserves(ethers.utils.parseEther("1000000"));

// 4. Activate presale
await stakingV2.setPresaleActive(true);

// 5. Set initial price
await stakingV2.setOzonePrice(ethers.utils.parseEther("91"));
```

---

## 7. Backend Integration

### Setup Backend

```javascript
// backend/config/contracts.js
const ethers = require('ethers');

const STAKING_ADDRESS = "0xYourStakingV2Address";
const STAKING_ABI = require('./abis/OzoneStakingV2.json');

const provider = new ethers.providers.JsonRpcProvider(
    'https://bsc-dataseed1.binance.org/'
);

const adminWallet = new ethers.Wallet(
    process.env.ADMIN_PRIVATE_KEY, 
    provider
);

const stakingContract = new ethers.Contract(
    STAKING_ADDRESS,
    STAKING_ABI,
    adminWallet
);

module.exports = { stakingContract, provider };
```

### Price Updater Service

**PENTING:** Backend harus update price dari DigiFinex secara berkala!

```javascript
// backend/services/priceUpdater.js
const axios = require('axios');
const { stakingContract } = require('../config/contracts');
const { ethers } = require('ethers');

class PriceUpdater {
    constructor() {
        this.updateInterval = 2 * 60 * 1000; // 2 minutes
        this.minPriceChange = 0.005; // 0.5%
        this.lastPrice = null;
    }
    
    async fetchDigiFinexPrice() {
        try {
            const response = await axios.get(
                'https://openapi.digifinex.com/v3/ticker',
                { params: { symbol: 'ozone_usdt' }, timeout: 10000 }
            );
            
            const price = parseFloat(response.data.ticker[0].last);
            
            if (isNaN(price) || price <= 0) {
                throw new Error('Invalid price');
            }
            
            console.log(`✅ DigiFinex price: $${price}`);
            return price;
            
        } catch (error) {
            console.error('❌ Error fetching price:', error.message);
            return null;
        }
    }
    
    async updatePriceOnChain(price) {
        try {
            const priceWei = ethers.utils.parseEther(price.toString());
            
            // Check current price
            const currentPrice = await stakingContract.ozonePrice();
            const currentPriceFloat = parseFloat(
                ethers.utils.formatEther(currentPrice)
            );
            
            // Only update if changed significantly
            if (this.lastPrice) {
                const change = Math.abs(
                    (price - currentPriceFloat) / currentPriceFloat
                );
                
                if (change < this.minPriceChange) {
                    console.log(`⏭️  Change ${(change * 100).toFixed(2)}% too small`);
                    return false;
                }
            }
            
            console.log(`📤 Updating: $${currentPriceFloat} → $${price}`);
            
            const tx = await stakingContract.setOzonePrice(priceWei, {
                gasLimit: 100000
            });
            
            console.log(`📡 TX: ${tx.hash}`);
            const receipt = await tx.wait();
            console.log(`✅ Updated in block ${receipt.blockNumber}`);
            console.log(`⛽ Gas: ${receipt.gasUsed.toString()}`);
            
            this.lastPrice = price;
            return true;
            
        } catch (error) {
            console.error('❌ Update error:', error.message);
            return false;
        }
    }
    
    async start() {
        console.log('🚀 Price Updater Started');
        console.log(`⏱️  Interval: ${this.updateInterval / 1000}s`);
        console.log(`📊 Min change: ${this.minPriceChange * 100}%`);
        
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

const priceUpdater = new PriceUpdater();
module.exports = priceUpdater;
```

### Start Service

```javascript
// backend/index.js
const priceUpdater = require('./services/priceUpdater');

// Start price updater
priceUpdater.start();

// ... rest of your backend
```

### API Endpoints (Optional)

```javascript
// backend/routes/staking.js
const express = require('express');
const router = express.Router();
const { stakingContract } = require('../config/contracts');
const { ethers } = require('ethers');

// Get current price
router.get('/price', async (req, res) => {
    try {
        const priceWei = await stakingContract.ozonePrice();
        const price = parseFloat(ethers.utils.formatEther(priceWei));
        
        res.json({
            success: true,
            data: { price, priceWei: priceWei.toString() }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Get user stakes
router.get('/user/:address', async (req, res) => {
    try {
        const { address } = req.params;
        
        if (!ethers.utils.isAddress(address)) {
            return res.status(400).json({ 
                success: false, 
                error: 'Invalid address' 
            });
        }
        
        const stakes = await stakingContract.getUserStakes(address);
        
        res.json({ success: true, data: stakes });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
```

---

## 8. Frontend Integration

### Setup Web3

```javascript
// frontend/utils/web3.js
import { ethers } from 'ethers';
import StakingABI from './abis/OzoneStakingV2.json';

const STAKING_ADDRESS = "0xYourStakingV2Address";
const USDT_ADDRESS = "0x55d398326f99059fF775485246999027B3197955";

export const getProvider = () => {
    if (window.ethereum) {
        return new ethers.providers.Web3Provider(window.ethereum);
    }
    throw new Error('Install MetaMask');
};

export const getStakingContract = (signer) => {
    return new ethers.Contract(STAKING_ADDRESS, StakingABI, signer);
};

export const getUSDTContract = (signer) => {
    const ABI = [
        'function approve(address spender, uint256 amount) returns (bool)',
        'function balanceOf(address owner) view returns (uint256)'
    ];
    return new ethers.Contract(USDT_ADDRESS, ABI, signer);
};
```

### Component: Buy & Stake

```javascript
// frontend/components/BuyAndStake.jsx
import { useState } from 'react';
import { ethers } from 'ethers';
import { getProvider, getStakingContract, getUSDTContract } from '../utils/web3';

function BuyAndStake() {
    const [poolId, setPoolId] = useState(1);
    const [usdtAmount, setUsdtAmount] = useState('');
    const [loading, setLoading] = useState(false);
    
    const handleBuy = async () => {
        try {
            setLoading(true);
            
            const provider = getProvider();
            const signer = provider.getSigner();
            const staking = getStakingContract(signer);
            const usdt = getUSDTContract(signer);
            
            // Parse amount (18 decimals for BSC USDT!)
            const baseAmount = ethers.utils.parseEther(usdtAmount);
            
            // Calculate total cost (base + 1% fee)
            const taxAmount = baseAmount.mul(100).div(10000);
            const totalCost = baseAmount.add(taxAmount);
            
            console.log('Base:', ethers.utils.formatEther(baseAmount));
            console.log('Tax (1%):', ethers.utils.formatEther(taxAmount));
            console.log('Total:', ethers.utils.formatEther(totalCost));
            
            // Approve total cost
            console.log('Approving USDT...');
            const approveTx = await usdt.approve(staking.address, totalCost);
            await approveTx.wait();
            console.log('✅ Approved');
            
            // Buy and stake
            console.log('Buying and staking...');
            const tx = await staking.buyAndStake(poolId, baseAmount, {
                gasLimit: 500000
            });
            
            console.log('TX:', tx.hash);
            await tx.wait();
            console.log('✅ Success!');
            
            alert('Successfully bought and staked OZONE!');
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
                <label>Pool:</label>
                <select value={poolId} onChange={(e) => setPoolId(e.target.value)}>
                    <option value={1}>LimoX A (6% APY)</option>
                    <option value={2}>LimoX B (7% APY)</option>
                    <option value={3}>LimoX C (8% APY)</option>
                    <option value={4}>SaproX A (9% APY)</option>
                    <option value={5}>SaproX B (10% APY)</option>
                </select>
            </div>
            
            <div className="form-group">
                <label>USDT Amount:</label>
                <input 
                    type="number"
                    value={usdtAmount}
                    onChange={(e) => setUsdtAmount(e.target.value)}
                    placeholder="1000"
                />
                <small>+ 1% platform fee will be added</small>
            </div>
            
            <button onClick={handleBuy} disabled={loading}>
                {loading ? 'Processing...' : 'Buy & Stake'}
            </button>
        </div>
    );
}

export default BuyAndStake;
```

### Component: Claim Rewards

```javascript
// frontend/components/ClaimRewards.jsx
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { getProvider, getStakingContract } from '../utils/web3';

function ClaimRewards() {
    const [stakes, setStakes] = useState([]);
    const [loading, setLoading] = useState(false);
    
    useEffect(() => {
        loadStakes();
    }, []);
    
    const loadStakes = async () => {
        try {
            const provider = getProvider();
            const signer = provider.getSigner();
            const address = await signer.getAddress();
            const staking = getStakingContract(signer);
            
            const userStakes = await staking.getUserStakes(address);
            setStakes(userStakes);
        } catch (error) {
            console.error('Error:', error);
        }
    };
    
    const handleClaim = async (index) => {
        try {
            setLoading(true);
            
            const provider = getProvider();
            const signer = provider.getSigner();
            const staking = getStakingContract(signer);
            
            console.log('Claiming stake', index);
            
            const tx = await staking.claimRewards(index, {
                gasLimit: 300000
            });
            
            console.log('TX:', tx.hash);
            await tx.wait();
            console.log('✅ Claimed!');
            
            alert('Rewards claimed successfully!');
            await loadStakes();
            
        } catch (error) {
            console.error('Error:', error);
            alert('Error: ' + error.message);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div className="claim-container">
            <h2>My Stakes</h2>
            
            {stakes.map((stake, index) => (
                <div key={index} className="stake-card">
                    <h3>Stake #{index + 1}</h3>
                    <p>Amount: {ethers.utils.formatEther(stake.amount)} OZONE</p>
                    <p>USDT Value: ${ethers.utils.formatEther(stake.usdtValueAtStake)}</p>
                    <p>APY: {stake.lockedAPY / 100}%</p>
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

## 9. Admin Operations

### Update Price

```javascript
// Manual price update
const newPrice = ethers.utils.parseEther("95"); // $95
await stakingV2.setOzonePrice(newPrice);
```

### Fund Reserves

```javascript
// Add USDT reserves for rewards
const amount = ethers.utils.parseEther("100000"); // 100k USDT
await usdtToken.approve(stakingV2Address, amount);
await stakingV2.fundUSDTReserves(amount);
```

### Monitor Stats

```javascript
// Check contract stats
const presaleSupply = await stakingV2.presaleSupply();
const totalSold = await stakingV2.totalPresaleSold();
const activeStakes = await stakingV2.activeStakeCount();
const reserves = await stakingV2.stakingUSDTReserves();

console.log({
    presaleSupply: ethers.utils.formatEther(presaleSupply),
    totalSold: ethers.utils.formatEther(totalSold),
    activeStakes: activeStakes.toString(),
    reserves: ethers.utils.formatEther(reserves)
});
```

### Emergency Operations

```javascript
// Pause contract
await stakingV2.pause();

// Unpause
await stakingV2.unpause();

// Upgrade (UUPS)
const NewImplementation = await ethers.getContractFactory("OzoneStakingV3");
await upgrades.upgradeProxy(stakingV2.address, NewImplementation);
```

---

## 10. Security & Audit

### Security Features

✅ **ReentrancyGuard** - Semua fungsi transfer protected  
✅ **Pausable** - Emergency stop mechanism  
✅ **UUPS Upgradeable** - Fix bugs tanpa migrasi  
✅ **Access Control** - OnlyOwner untuk admin functions  
✅ **OpenZeppelin Contracts** - Battle-tested libraries  

### Best Practices

```solidity
// ✅ Checks-Effects-Interactions pattern
function claimRewards() external {
    // 1. Checks
    require(stake.isActive, "Not active");
    require(rewards > 0, "No rewards");
    
    // 2. Effects (update state)
    stake.totalClaimed += rewards;
    stake.lastClaimTime = block.timestamp;
    
    // 3. Interactions (external calls)
    usdtToken.transfer(msg.sender, rewards);
}
```

### Audit Checklist

- [ ] ReentrancyGuard pada semua transfer functions
- [ ] Input validation pada semua parameters
- [ ] Access control (onlyOwner) pada admin functions
- [ ] Pausable untuk emergency
- [ ] Event logging untuk transparency
- [ ] Gas optimization
- [ ] Upgrade mechanism tested

---

## 📞 Support & Contact

**Website:** https://ozone.com  
**Telegram:** https://t.me/ozone  
**Email:** support@ozone.com

---

## 📝 License

MIT License - Copyright (c) 2025 OZONE Team

---

**🔐 DISCLAIMER:**

Contract ini melibatkan risiko finansial. User harus:
- Memahami mekanisme sebelum invest
- Hanya invest yang mampu ditanggung risikonya
- Sadar bahwa OZONE principal akan di-burn
- DYOR (Do Your Own Research)

**Ini bukan financial advice!**

---

**Built with ❤️ by OZONE Team | December 2025**

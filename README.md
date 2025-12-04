# 🏭 OZONE Staking V2 - Integrated Presale & Staking Platform

![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Network](https://img.shields.io/badge/Network-BSC-yellow)
![Pattern](https://img.shields.io/badge/Pattern-UUPS%20Upgradeable-orange)
![Tax](https://img.shields.io/badge/Tax-1%25%20USDT%20%2B%201%25%20OZONE-red)

**Production-ready integrated presale & staking platform with automatic tax collection and USDT-only rewards.**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Contract Components](#contract-components)
- [Tier System](#tier-system)
- [User Flow](#user-flow)
- [Deployment Guide](#deployment-guide)
- [Admin Operations](#admin-operations)
- [Smart Contract Addresses](#smart-contract-addresses)
- [Security](#security)
- [License](#license)

---

## 🎯 Overview

OZONE Staking V2 adalah **platform terintegrasi presale + staking dalam 1 contract** yang memungkinkan:

- **Buy & Stake**: Beli OZONE dengan USDT dan langsung auto-stake (1 transaksi!)
- **Manual Stake**: Stake OZONE yang sudah dimiliki ke pool pilihan
- **USDT Rewards Only**: Semua rewards dibayar dalam USDT (stablecoin)
- **Tax System**: 1% USDT platform fee + 1% OZONE transfer tax (auto-collected)
- **5 Pool Tiers**: LimoX A/B/C (6-8% APY), SaproX A/B (9-10% APY)
- **Anti-Dump**: OZONE dari presale langsung stake, tidak masuk wallet
- **Auto-Burn**: Principal OZONE burn setelah durasi habis
- **Upgradeable**: UUPS proxy pattern untuk future improvements

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────┐
│              OZONE STAKING V2 ECOSYSTEM                 │
│         (1 Contract - Integrated Solution)              │
├────────────────────────────────────────────────────────┤
│                                                         │
│  📦 OzoneStakingV2.sol (UUPS Upgradeable)             │
│                                                         │
│  🛒 PRESALE FEATURE                                     │
│  ├─ For: New buyers                                    │
│  ├─ Input: USDT payment                                │
│  ├─ Function: buyAndStake(poolId, usdtAmount)          │
│  ├─ Price: Manual update from DigiFinex API            │
│  ├─ Tax: 1% USDT platform fee (auto-deducted)          │
│  ├─ Anti-dump: OZONE stays in contract                 │
│  └─ Flow: USDT → Buy OZONE → Auto-stake                │
│                                                         │
│  💎 STAKING FEATURE                                     │
│  ├─ For: Existing OZONE holders                        │
│  ├─ Input: OZONE tokens from wallet                    │
│  ├─ Function: stake(poolId, ozoneAmount)               │
│  ├─ Tax: 1% OZONE transfer tax (tracks original)       │
│  ├─ Conversion: OZONE → USDT value (ozonePrice)        │
│  └─ Flow: OZONE → Calculate USDT value → Stake         │
│                                                         │
│  🎁 REWARDS & CLAIMS                                    │
│  ├─ Reward Type: USDT only (no OZONE option)           │
│  ├─ APY: 6-10% monthly (based on pool)                 │
│  ├─ Claim: Anytime after first stake                   │
│  ├─ Calculation: Based on original USDT value          │
│  └─ Distribution: From USDT reserve pool               │
│                                                         │
│  🔥 AUTO-BURN MECHANISM                                 │
│  ├─ Trigger: Pool duration completed                   │
│  ├─ Action: Burn principal OZONE tokens                │
│  ├─ Benefit: Deflationary tokenomics                   │
│  └─ User: Keeps all USDT rewards earned                │
│                                                         │
│  💰 TAX COLLECTION                                      │
│  ├─ USDT Tax: 1% on buyAndStake (platform fee)         │
│  ├─ OZONE Tax: 1% on stake (transfer tax)              │
│  ├─ Tracking: originalAmount vs amount after tax       │
│  ├─ Destination: Tax wallet (configurable)             │
│  └─ Rewards: Based on originalAmount (pre-tax)         │
│                                                         │
│  🏆 POOL TIERS                                          │
│  ├─ LimoX Pool A: $100-1K (6% APY)                     │
│  ├─ LimoX Pool B: $1K-3K (7% APY)                      │
│  ├─ LimoX Pool C: $3K-5K (8% APY)                      │
│  ├─ SaproX Pool A: $5K-10K (9% APY)                    │
│  └─ SaproX Pool B: $10K+ (10% APY)                     │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 💰 **Integrated Presale & Staking**
One contract handles both:
- Buy OZONE with USDT → Auto-stake (1 transaction)
- Stake existing OZONE → Earn USDT rewards
- No need for separate presale contract

### 🏦 **Tax System**
Automatic tax collection with transparent tracking:
- **1% USDT Platform Fee** - Deducted from buyAndStake()
- **1% OZONE Transfer Tax** - Deducted from stake()
- Tax goes to configurable tax wallet
- Rewards calculated on **original amount** (before tax)

### 🎁 **USDT-Only Rewards**
Simplified reward system:
- All rewards paid in USDT stablecoin
- No OZONE reward option (removed for simplicity)
- Predictable value, no price volatility
- Easier for users to understand

### 🏆 **5 Pool Tiers**
Manual pool selection with locked rates:
- User chooses pool based on investment
- APY locked at stake time (6-10% monthly)
- Pool requirements: LimoX ($100-5K), SaproX ($5K-10K+)

### ⏰ **Flexible Claiming**
Claim anytime after first stake:
- No minimum wait time
- No maximum claim limit
- Rewards accumulate continuously
- Claim as often as you want

### 🔒 **Security Features**
- ReentrancyGuard on all critical functions
- Pausable for emergency stops
- UUPS upgradeable (fix bugs without migration)
- OpenZeppelin battle-tested contracts

### 🔥 **Auto-Burn Mechanism**
Deflationary tokenomics:
- Principal OZONE burned when pool duration ends
- Reduces circulating supply
- Benefits all token holders
- User keeps 100% of USDT rewards earned

### 📊 **Transparent Tracking**
Full visibility on tax impact:
- `originalAmount`: Pre-tax amount (for reward calculation)
- `amount`: Post-tax amount (after 1% deduction)
- `usdtValueAtStake`: USDT equivalent locked in

---

## 📦 Contract Components

### OzoneStakingV2.sol - Integrated Presale & Staking

**Purpose**: Single contract handling both presale and staking with automatic tax collection

**User Functions**:
```solidity
// Buy OZONE with USDT and auto-stake (1 transaction)
// Note: 1% USDT platform fee auto-deducted
function buyAndStake(uint256 poolId, uint256 baseUSDTAmount) external

// Stake existing OZONE tokens manually
// Note: 1% OZONE transfer tax auto-deducted
function stake(uint256 poolId, uint256 ozoneAmount) external

// Claim USDT rewards anytime
function claimRewards(uint256 stakeIndex) external

// Get claimable rewards
function calculateClaimableRewards(address user, uint256 stakeIndex) 
    external view returns (uint256 claimableRewards)

// View user stakes
function getUserStakes(address user) 
    external view returns (Stake[] memory)

// Get pool information
function pools(uint256 poolId) 
    external view returns (Pool memory)
```

**Admin Functions**:
```solidity
// Fund USDT reserves for rewards
function fundUSDTReserves(uint256 amount) external onlyOwner

// Price management (update from DigiFinex API)
function setOzonePrice(uint256 _priceInUSDT) external onlyOwner

// Tax wallet management
function setTaxWallet(address _taxWallet) external onlyOwner

// Treasury management
function setTreasuryWallet(address _treasuryWallet) external onlyOwner

// Presale control
function setPresaleActive(bool _isActive) external onlyOwner
function setPresaleSupply(uint256 _supply) external onlyOwner

// Pool management
function addPool(string memory name, uint256 monthlyAPY, uint256 durationDays, 
                 uint256 minStakeUSDT, uint256 maxStakeUSDT) external onlyOwner
function setPoolActive(uint256 poolId, bool isActive) external onlyOwner

// Emergency
function pause() external onlyOwner
function unpause() external onlyOwner

// Upgrade
function upgradeTo(address newImplementation) external onlyOwner
```

**Important Notes**:
- **USDT Decimals**: 18 (not 6!) - BEP-20 USDT on BSC uses 18 decimals
- **OZONE Decimals**: 18
- **Tax Tracking**: `originalAmount` (pre-tax) vs `amount` (post-tax)
- **Rewards**: Always calculated from `originalAmount` (fair to users)
- **Price**: Must be updated regularly from DigiFinex API via backend service

---

## 🏆 Tier System

### Pool Configuration

| Pool Name | USDT Range | Monthly APY | Basis Points | Target Users |
|-----------|------------|-------------|--------------|--------------|
| **LimoX Pool A** | $100 - $1,000 | 6% | 600 | Retail investors |
| **LimoX Pool B** | $1,001 - $3,000 | 7% | 700 | Experienced users |
| **LimoX Pool C** | $3,001 - $5,000 | 8% | 800 | Mid-tier investors |
| **SaproX Pool A** | $5,001 - $10,000 | 9% | 900 | High net worth |
| **SaproX Pool B** | $10,001+ | 10% | 1000 | Whales/Institutions |

### Reward Calculation Formula

```
Daily Reward = (Original Amount × Locked APY) / 10,000 / 30
Total Reward = Daily Reward × Days Elapsed
Max Reward (USDT) = USDT Value at Stake × 300%
```

### Example Calculation

**Investment**: $5,000 USDT (via buyAndStake)  
**OZONE Price**: $91 (from DigiFinex)  
**Pool**: SaproX Pool A (9% monthly APY, 360 days)

```
// Step 1: Calculate costs
Base Amount = $5,000 USDT
Platform Fee (1%) = $50 USDT → Tax Wallet
Net to Treasury = $4,950 USDT

// Step 2: Calculate OZONE
OZONE Received = $5,000 / $91 = 54.95 OZONE
Staked to Pool = 54.95 OZONE

// Step 3: Calculate rewards
Monthly APY = 9% (900 basis points)
Monthly Reward = $5,000 × 9% = $450 USDT/month
Pool Duration = 360 days (12 months)
Total Rewards = $450 × 12 = $5,400 USDT

// Step 4: Final outcome
After 360 days:
- Total USDT earned: $5,400 USDT
- Principal OZONE: 54.95 OZONE burned 🔥
- Net Profit: $400 USDT (8% ROI after burn)
- User keeps: $5,400 USDT in wallet
```

**Tax Breakdown**:
```
User pays: $5,050 USDT total
├─ $5,000 → buyAndStake(poolId, 5000e18)
├─ $50 → 1% platform fee (auto-deducted)
└─ Total approved: 5050e18 (base + 1%)

Distribution:
├─ $50 → Tax Wallet (1% USDT fee)
├─ $4,950 → Treasury Wallet (net presale revenue)
└─ 54.95 OZONE → Staked in contract (never to user wallet)
```

---

## 👤 User Flow

### For New Buyers (via buyAndStake)

```javascript
// 1. Get current OZONE price
const price = await stakingV2.ozonePrice();
console.log("OZONE Price:", ethers.utils.formatEther(price), "USDT");
// Example: $91.00

// 2. Calculate costs
const baseAmount = ethers.utils.parseEther("5000"); // $5,000 USDT
const taxAmount = baseAmount.mul(100).div(10000); // 1% = $50
const totalCost = baseAmount.add(taxAmount); // $5,050 total
const ozoneAmount = baseAmount.mul(ethers.utils.parseEther("1")).div(price);
console.log("OZONE to receive:", ethers.utils.formatEther(ozoneAmount));
// Example: 54.95 OZONE

// 3. Approve USDT (total cost including tax)
await usdtToken.approve(stakingV2Address, totalCost);

// 4. Buy and auto-stake (ONE TRANSACTION!)
await stakingV2.buyAndStake(
    4, // SaproX Pool A
    baseAmount // $5,000 (tax added automatically)
);

// Result:
// ✅ $5,050 USDT deducted from wallet
// ✅ $50 → Tax Wallet (1% platform fee)
// ✅ $5,000 → Treasury Wallet
// ✅ 54.95 OZONE staked to SaproX Pool A
// ✅ Earning $450/month in USDT
// ✅ OZONE never touched wallet (anti-dump!)
```

### For Existing OZONE Holders (via stake)

```javascript
// 1. Check OZONE balance
const balance = await ozoneToken.balanceOf(userAddress);
const stakeAmount = ethers.utils.parseEther("100"); // 100 OZONE

// 2. Calculate tax
const taxAmount = stakeAmount.mul(100).div(10000); // 1% = 1 OZONE
const netStake = stakeAmount.sub(taxAmount); // 99 OZONE staked

// 3. Get USDT value for rewards
const price = await stakingV2.ozonePrice(); // $91
const usdtValue = stakeAmount.mul(price).div(ethers.utils.parseEther("1"));
console.log("USDT Value:", ethers.utils.formatEther(usdtValue));
// Example: $9,100 USDT equivalent

// 4. Approve OZONE
await ozoneToken.approve(stakingV2Address, stakeAmount);

// 5. Stake to chosen pool
await stakingV2.stake(
    4, // SaproX Pool A (9% APY)
    stakeAmount // 100 OZONE
);

// Result:
// ✅ 100 OZONE deducted from wallet
// ✅ 1 OZONE → Tax Wallet (1% transfer tax)
// ✅ 99 OZONE staked in contract
// ✅ Rewards based on 100 OZONE (originalAmount)
// ✅ Earning based on $9,100 USDT value
```

### Claim Rewards

```javascript
// 1. Check claimable rewards
const rewards = await stakingV2.calculateClaimableRewards(userAddress, 0);
console.log("Claimable:", ethers.utils.formatEther(rewards), "USDT");

// 2. Claim anytime (no minimum wait)
await stakingV2.claimRewards(0); // stake index 0

// 3. USDT sent to your wallet
// ✅ Rewards paid in USDT only
// ✅ No OZONE option (simplified)
```

---

## 🚀 Deployment Guide

### Prerequisites

```bash
npm install --save-dev hardhat
npm install @openzeppelin/contracts-upgradeable
npm install @openzeppelin/hardhat-upgrades
npm install @chainlink/contracts
npm install ethers
```

### Step 1: Deploy Staking V2

```javascript
const { ethers, upgrades } = require("hardhat");

async function main() {
    // Get contract factory
    const OzoneStakingV2 = await ethers.getContractFactory("OzoneStakingV2");
    
    // Deploy with proxy
    const stakingV2 = await upgrades.deployProxy(
        OzoneStakingV2,
        [
            ozoneTokenAddress,      // OZONE token
            usdtTokenAddress,       // USDT token
            ozoneContractAddress,   // OZONE main contract
            ethers.utils.parseEther("1") // Initial price $1.00
        ],
        { initializer: 'initialize', kind: 'uups' }
    );
    
    await stakingV2.deployed();
    console.log("StakingV2 deployed to:", stakingV2.address);
}
```

### Step 2: Deploy Presale V2

```javascript
async function main() {
    const OzonePresaleV2 = await ethers.getContractFactory("OzonePresaleV2");
    
    const presaleV2 = await upgrades.deployProxy(
        OzonePresaleV2,
        [
            ozoneTokenAddress,
            usdtTokenAddress,
            stakingV2.address,      // From Step 1
            treasuryAddress,
            ethers.utils.parseEther("1"), // Initial price
            ethers.utils.parseEther("10000000") // 10M OZONE supply
        ],
        { initializer: 'initialize', kind: 'uups' }
    );
    
    await presaleV2.deployed();
    console.log("PresaleV2 deployed to:", presaleV2.address);
}
```

### Step 3: Configure Integration

```javascript
// 1. Authorize Presale to create stakes
await stakingV2.setAuthorizedStakeCreator(presaleV2.address, true);

// 2. Fund StakingV2 USDT reserves
await usdtToken.approve(
    stakingV2.address, 
    ethers.utils.parseUnits("1000000", 6)
);
await stakingV2.fundUSDTReserves(
    ethers.utils.parseUnits("1000000", 6) // 1M USDT
);

// 3. Fund StakingV2 OZONE reserves (for dual rewards)
await ozoneToken.approve(
    stakingV2.address,
    ethers.utils.parseEther("5000000")
);
await stakingV2.fundOzoneReserves(
    ethers.utils.parseEther("5000000") // 5M OZONE
);

// 4. Fund PresaleV2 with OZONE supply
await ozoneToken.approve(
    presaleV2.address,
    ethers.utils.parseEther("10000000")
);
await presaleV2.addPresaleSupply(
    ethers.utils.parseEther("10000000") // 10M OZONE
);
```

### Step 4: Setup Price Oracle

#### Option A: Chainlink (Recommended)
```javascript
// If OZONE has Chainlink price feed
const chainlinkFeed = "0x..."; // OZONE/USDT feed address

await presaleV2.setChainlinkPriceFeed(chainlinkFeed);
await presaleV2.setPriceSource(1); // PriceSource.CHAINLINK
```

#### Option B: Manual (Temporary)
```javascript
// Update price manually from Digifinex/CoinGecko
await presaleV2.setPriceSource(0); // PriceSource.MANUAL
await presaleV2.updateManualPrice(
    ethers.utils.parseEther("0.85") // $0.85
);
```

---

## ⚙️ Admin Operations

### Daily Price Update (Manual Mode)

```javascript
// Fetch price from exchange
const price = await fetchPriceFromDigifinex();

// Update contract
await presaleV2.updateManualPrice(
    ethers.utils.parseEther(price.toString())
);

// Or update staking contract
await stakingV2.setOzonePrice(
    ethers.utils.parseEther(price.toString())
);
```

### Monitor Reserves

```javascript
const [
    activeStakes,
    usdtDistributed,
    ozoneDistributed,
    tokensBurned,
    usdtReserves,
    ozoneReserves
] = await stakingV2.getStakingStats();

console.log({
    activeStakes: activeStakes.toString(),
    usdtReserves: ethers.utils.formatUnits(usdtReserves, 6),
    ozoneReserves: ethers.utils.formatEther(ozoneReserves),
    burnedTokens: ethers.utils.formatEther(tokensBurned)
});

// Alert if reserves low
if (usdtReserves < ethers.utils.parseUnits("100000", 6)) {
    console.warn("⚠️ USDT reserves below $100k!");
}
```

### Monitor Presale

```javascript
const stats = await presaleV2.getPresaleStats();

console.log({
    totalRaised: ethers.utils.formatUnits(stats.totalRaised, 6),
    totalSold: ethers.utils.formatEther(stats.totalSold),
    uniqueBuyers: stats.totalBuyers.toString(),
    soldPercent: stats.soldPercent.toString() + "%",
    remaining: ethers.utils.formatEther(stats.remaining)
});
```

### Emergency Operations

```javascript
// Pause contracts
await stakingV2.pause();
await presaleV2.pause();

// Withdraw reserves (only when paused)
await stakingV2.withdrawUSDTReserves(amount);
await presaleV2.emergencyWithdraw(tokenAddress, amount);

// Unpause
await stakingV2.unpause();
await presaleV2.unpause();
```

---

## 📍 Smart Contract Addresses

### BSC Mainnet

```
OzoneStakingV2 Proxy: 0x... (To be deployed)
OzoneStakingV2 Implementation: 0x...

OzonePresaleV2 Proxy: 0x...
OzonePresaleV2 Implementation: 0x...

OZONE Token: 0x... (Existing)
USDT BEP-20: 0x55d398326f99059fF775485246999027B3197955
```

### BSC Testnet

```
OzoneStakingV2 Proxy: 0x... (Testing)
OzonePresaleV2 Proxy: 0x... (Testing)
```

---

## 🔒 Security

### Audits
- ⏳ Pending professional audit
- ✅ OpenZeppelin contracts used
- ✅ ReentrancyGuard on all critical functions
- ✅ Pausable for emergency stops
- ✅ UUPS upgradeable for bug fixes

### Security Features

1. **ReentrancyGuard**: Prevents reentrancy attacks
2. **Pausable**: Emergency pause mechanism
3. **Access Control**: OnlyOwner for admin functions
4. **Price Bounds**: Min/max price limits
5. **Stale Price Check**: Oracle data freshness validation
6. **Authorized Callers**: Only Presale can create stakes
7. **Supply Tracking**: Prevent over-allocation

### Best Practices

```solidity
// ✅ All external transfers checked
require(token.transfer(...), "Transfer failed");

// ✅ ReentrancyGuard on all state-changing functions
function buyAndStake() external nonReentrant { ... }

// ✅ Input validation
require(amount > 0, "Amount must be positive");
require(address != address(0), "Invalid address");

// ✅ Safe math (Solidity 0.8.20 has built-in overflow checks)
```

---

## 🔄 Upgrade Process

### Upgrade Staking V2

```javascript
// Deploy new implementation
const OzoneStakingV3 = await ethers.getContractFactory("OzoneStakingV3");

// Upgrade via proxy
await upgrades.upgradeProxy(stakingV2.address, OzoneStakingV3);

console.log("StakingV2 upgraded to V3");
// Proxy address stays the same ✅
```

### Upgrade Presale V2

```javascript
const OzonePresaleV3 = await ethers.getContractFactory("OzonePresaleV3");
await upgrades.upgradeProxy(presaleV2.address, OzonePresaleV3);

console.log("PresaleV2 upgraded to V3");
```

---

## 📊 Statistics & Analytics

### View Functions

```javascript
// User stats
const userStats = await presaleV2.getUserStats(userAddress);
// Returns: totalSpent, totalReceived, purchaseCount, averagePrice

// User stakes
const stakes = await stakingV2.getUserStakes(userAddress);
// Returns: Array of all user stakes

// Reward breakdown
const [claimable, usdtAmount, ozoneAmount] = 
    await stakingV2.getRewardBreakdown(userAddress, stakeIndex, rewardType);

// Time until next claim
const timeLeft = await stakingV2.getTimeUntilNextClaim(userAddress, stakeIndex);

// Global stats
const globalStats = await stakingV2.getStakingStats();
const presaleStats = await presaleV2.getPresaleStats();
```

---

## 🧪 Testing

```bash
# Run tests
npx hardhat test

# Run coverage
npx hardhat coverage

# Deploy to testnet
npx hardhat run scripts/deploy.js --network bscTestnet

# Verify contracts
npx hardhat verify --network bscMainnet DEPLOYED_ADDRESS
```

---

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📞 Support & Community

- **Website**: https://ozone.com
- **Telegram**: https://t.me/ozone
- **Twitter**: https://twitter.com/ozone
- **Email**: support@ozone.com

---

## ⚠️ Disclaimer

This smart contract system involves financial risk. Users should:
- Understand the mechanics before investing
- Only invest what they can afford to lose
- Be aware of smart contract risks
- Understand that OZONE principal is burned at 300% reward
- Know that past performance doesn't guarantee future results

**This is not financial advice. DYOR (Do Your Own Research).**

---

## 🗺️ Roadmap

### Q4 2025
- ✅ Smart contract development
- ⏳ Security audit
- ⏳ BSC mainnet deployment
- ⏳ Presale launch

### Q1 2026
- ⏳ Chainlink oracle integration
- ⏳ DEX TWAP implementation
- ⏳ Dashboard v2.0
- ⏳ Mobile app

### Q2 2026
- ⏳ Cross-chain expansion
- ⏳ Governance token integration
- ⏳ DAO implementation

---

**Built with ❤️ by OZONE Team | December 2025**

---

## 📚 Technical Documentation

For detailed technical documentation, see:
- [TECHNICAL.md](./TECHNICAL.md) - Deep dive into smart contracts
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Complete deployment guide
- [API.md](./API.md) - Function reference
- [SECURITY.md](./SECURITY.md) - Security considerations

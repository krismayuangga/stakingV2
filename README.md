# 🏭 OZONE Staking V2 - Dual Reward Staking Platform

![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Network](https://img.shields.io/badge/Network-BSC-yellow)
![Pattern](https://img.shields.io/badge/Pattern-UUPS%20Upgradeable-orange)

**Production-ready dual reward staking ecosystem with auto-tier system and real-time price oracle integration.**

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

OZONE Staking V2 adalah platform staking dual-reward dengan sistem tier otomatis yang memungkinkan:

- **Holder Lama**: Stake OZONE tokens langsung ke pool pilihan
- **Buyer Baru**: Beli OZONE dengan USDT dan langsung auto-stake (1 transaksi)
- **Dual Rewards**: Pilih reward dalam USDT atau OZONE
- **Auto-Tier**: Pool ditentukan otomatis berdasarkan nilai USDT investasi
- **Anti-Dump**: OZONE dari presale tidak pernah masuk wallet user
- **300% Max Reward**: Principal auto-burn setelah mencapai 300% reward
- **Upgradeable**: UUPS proxy pattern untuk future improvements

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────┐
│                  OZONE V2 ECOSYSTEM                     │
├────────────────────────────────────────────────────────┤
│                                                         │
│  📦 OzoneStakingV2.sol (UUPS Upgradeable)             │
│  ├─ For: Existing OZONE holders                        │
│  ├─ Input: OZONE tokens                                │
│  ├─ Function: stake(poolId, amount)                    │
│  ├─ Claim: Every 15 days (time-based)                  │
│  ├─ Rewards: USDT or OZONE (user choice)               │
│  └─ Exit: Auto-burn at 300% max reward                 │
│                                                         │
│  📦 OzonePresaleV2.sol (UUPS Upgradeable)              │
│  ├─ For: New buyers via presale                        │
│  ├─ Input: USDT payment                                │
│  ├─ Function: buyAndStake(usdtAmount)                  │
│  ├─ Price: Real-time (Chainlink/Manual)                │
│  ├─ Auto-tier: Based on USDT amount                    │
│  ├─ Anti-dump: OZONE stays in staking contract         │
│  └─ Rewards: USDT only (presale buyers)                │
│                                                         │
│  🔗 Shared Features:                                    │
│  ├─ 5 Tier pools (LimoX A/B/C, SaproX A/B)            │
│  ├─ 6-10% monthly APY                                   │
│  ├─ 300% max reward + auto-burn principal              │
│  ├─ Claim every 15 days (any amount)                   │
│  └─ Tier & APY locked at stake time                    │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 🎯 **Auto-Tier System**
Automatically assigns pool/tier based on USDT investment value:
- No manual pool selection needed for presale buyers
- Fair and transparent tier allocation
- Bigger investment = Higher APY

### ⏰ **Time-Based Claiming**
- Claim every **15 days** (any amount)
- No minimum claim requirement
- Rewards auto-accumulate if not claimed

### 🔒 **Tier Locking**
- Pool, APY, and USDT value **locked at stake time**
- Price fluctuations don't affect your tier
- Predictable and fair for all users

### 🤖 **Price Oracle Integration**
Three price source options:
1. **Manual** - Owner updates price (default, flexible)
2. **Chainlink** - Fully automatic oracle (recommended)
3. **DEX TWAP** - Time-weighted average price (future)

### 💰 **Dual Reward System**
- **USDT rewards**: Stable income, predictable value
- **OZONE rewards**: Ecosystem participation, potential upside
- User chooses reward type per claim

### 🔥 **Auto-Burn Mechanism**
- Maximum reward: **300% of USDT value at stake**
- Upon reaching 300%, principal OZONE tokens are **burned**
- Deflationary mechanism benefits all holders
- Net profit: 200% (3x reward - 1x principal)

### 🔄 **UUPS Upgradeable**
- Fix bugs without migration
- Add features seamlessly
- Same address forever
- User funds always safe

---

## 📦 Contract Components

### 1. OzoneStakingV2.sol

**Purpose**: Core staking platform for OZONE holders

**Key Functions**:
```solidity
// Manual staking by OZONE holders
function stake(uint256 poolId, uint256 amount) external

// Auto-staking via Presale contract
function createStakeForUser(address user, uint256 poolId, uint256 ozoneAmount, uint256 usdtValue) external

// Claim rewards (USDT by default)
function claimRewards(uint256 stakeIndex) external

// Claim rewards with type selection
function claimRewardsWithType(uint256 stakeIndex, RewardType rewardType) external

// Optional early unstake (before 300%)
function unstake(uint256 stakeIndex) external
```

**Admin Functions**:
```solidity
// Fund reserves
function fundUSDTReserves(uint256 amount) external onlyOwner
function fundOzoneReserves(uint256 amount) external onlyOwner

// Price management
function setOzonePrice(uint256 price) external onlyOwner

// Authorize Presale contract
function setAuthorizedStakeCreator(address creator, bool status) external onlyOwner

// Upgrade
function upgradeTo(address newImplementation) external onlyOwner
```

---

### 2. OzonePresaleV2.sol

**Purpose**: Buy OZONE and auto-stake in one transaction

**Key Functions**:
```solidity
// Buy OZONE and auto-stake
function buyAndStake(uint256 usdtAmount) external

// Calculate OZONE for USDT
function calculateOzoneForUSDT(uint256 usdtAmount) external view returns (uint256 ozoneAmount, uint256 currentPrice, uint256 poolId)

// Validate purchase
function validatePurchase(uint256 usdtAmount) external view returns (bool isValid, string memory reason, uint256 ozoneAmount, uint256 poolId)

// Get presale stats
function getPresaleStats() external view returns (uint256 totalRaised, uint256 totalSold, uint256 totalBuyers, ...)
```

**Admin Functions**:
```solidity
// Price oracle management
function setPriceSource(PriceSource source) external onlyOwner
function setChainlinkPriceFeed(address priceFeed) external onlyOwner
function updateManualPrice(uint256 newPrice) external onlyOwner

// Supply management
function addPresaleSupply(uint256 amount) external onlyOwner

// Limits
function updatePurchaseLimits(uint256 minUSDT, uint256 maxUSDT) external onlyOwner
```

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

**Investment**: $5,000 USDT  
**OZONE Price**: $0.85  
**OZONE Amount**: 5,882 OZONE  
**Pool**: SaproX Pool A (9% APY)

```
Daily Reward = (5000 × 900) / 10,000 / 30 = $15 USDT/day
Monthly Reward = $15 × 30 = $450 USDT
Max Reward = $5,000 × 300% = $15,000 USDT
Time to Max = $15,000 / $450 = 33.3 months

Timeline:
- Month 1-33: Earn $450/month
- After 33 months: Total earned $15,000
- Auto-burn: 5,882 OZONE principal burned 🔥
- Net Profit: $10,000 (200% gain)
```

---

## 👤 User Flow

### For New Buyers (Presale)

```javascript
// 1. Check investment outcome
const [ozoneAmount, price, poolId] = await presaleV2.calculateOzoneForUSDT(
    ethers.utils.parseUnits("5000", 6) // $5,000 USDT
);
// Returns: 5882 OZONE, $0.85 price, Pool 4 (SaproX Pool A)

// 2. Validate purchase
const [isValid, reason] = await presaleV2.validatePurchase(
    ethers.utils.parseUnits("5000", 6)
);
// Returns: true, "Valid purchase"

// 3. Approve USDT
await usdtToken.approve(presaleAddress, ethers.utils.parseUnits("5000", 6));

// 4. Buy and auto-stake (ONE TRANSACTION!)
await presaleV2.buyAndStake(ethers.utils.parseUnits("5000", 6));

// Result:
// ✅ $5,000 USDT → Treasury
// ✅ 5,882 OZONE bought
// ✅ Auto-staked to SaproX Pool A
// ✅ Earning $15/day (~$450/month)
// ✅ OZONE never touched wallet (anti-dump!)
```

### For Existing OZONE Holders (Staking)

```javascript
// 1. Approve OZONE
await ozoneToken.approve(stakingAddress, ethers.utils.parseEther("5882"));

// 2. Choose pool and stake
await stakingV2.stake(
    4, // SaproX Pool A
    ethers.utils.parseEther("5882")
);

// 3. Wait 15 days

// 4. Claim rewards
await stakingV2.claimRewardsWithType(
    0, // stake index
    0  // RewardType.USDT_ONLY
);
// Or choose OZONE rewards:
await stakingV2.claimRewardsWithType(0, 1); // RewardType.OZONE_ONLY
```

### Claim Schedule

```
Day 0: Stake $5,000 worth
Day 15: Can claim ~$225 USDT ✅
Day 30: Can claim ~$225 USDT ✅
Day 45: Can claim ~$225 USDT ✅
...
Day 1000: Reached $15,000 total
        → Principal auto-burned 🔥
        → Stake completed
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

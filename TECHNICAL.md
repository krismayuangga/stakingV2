# 📘 Technical Documentation - OZONE Staking V2

## Table of Contents
1. [Smart Contract Architecture](#smart-contract-architecture)
2. [Detailed Function Reference](#detailed-function-reference)
3. [Reward Calculation Logic](#reward-calculation-logic)
4. [Auto-Burn Mechanism](#auto-burn-mechanism)
5. [Price Oracle Integration](#price-oracle-integration)
6. [Upgrade Mechanism](#upgrade-mechanism)
7. [Gas Optimization](#gas-optimization)
8. [Error Codes](#error-codes)

---

## 🏗️ Smart Contract Architecture

### Contract Inheritance Hierarchy

```
OzoneStakingV2
├── Initializable (OpenZeppelin)
├── UUPSUpgradeable (OpenZeppelin)
├── OwnableUpgradeable (OpenZeppelin)
├── PausableUpgradeable (OpenZeppelin)
└── ReentrancyGuardUpgradeable (OpenZeppelin)

OzonePresaleV2
├── Initializable (OpenZeppelin)
├── UUPSUpgradeable (OpenZeppelin)
├── OwnableUpgradeable (OpenZeppelin)
├── PausableUpgradeable (OpenZeppelin)
└── ReentrancyGuardUpgradeable (OpenZeppelin)
```

### Storage Layout

#### OzoneStakingV2 Storage

```solidity
// Immutable references (not in storage slots for upgradeable)
IERC20 public ozoneToken;
IERC20 public usdtToken;
IOZONEToken public ozoneContract;

// Pool system
mapping(uint256 => Pool) public pools;
mapping(address => UserStake[]) public userStakes;
uint256 public totalPools;
uint256 public nextPoolId;

// Reserves
uint256 public stakingUSDTReserves;
uint256 public ozoneReserves;
uint256 public totalStakingDistributed;
uint256 public totalOzoneDistributed;
uint256 public totalTokensBurned;
uint256 public activeStakeCount;

// Authorization
mapping(address => bool) public authorizedStakeCreators;

// Price
uint256 public ozonePrice;
```

⚠️ **Important**: Never change the order of state variables in upgrades to avoid storage collision!

---

## 📋 Detailed Function Reference

### OzoneStakingV2 Functions

#### `initialize()`
```solidity
function initialize(
    address _ozoneToken,
    address _usdtToken,
    address _ozoneContract,
    uint256 _initialOzonePrice
) public initializer
```
**Purpose**: Initialize the upgradeable contract (replaces constructor)

**Parameters**:
- `_ozoneToken`: OZONE ERC20 token address
- `_usdtToken`: USDT BEP-20 token address
- `_ozoneContract`: OZONE main contract for PoR
- `_initialOzonePrice`: Initial OZONE price (18 decimals)

**Access**: Can only be called once during deployment

**Gas Cost**: ~500,000 (includes 5 pool initializations)

---

#### `stake()`
```solidity
function stake(uint256 _poolId, uint256 _amount) external nonReentrant whenNotPaused
```
**Purpose**: Manual staking by OZONE holders

**Flow**:
1. Validate pool exists and is active
2. Calculate USDT value based on current price
3. Validate amount fits pool range
4. Transfer OZONE from user to contract
5. Create stake entry with locked tier/APY
6. Update pool stats

**Requirements**:
- `_poolId` must be valid (1-5)
- `_amount` must be > 0
- Pool must be active
- USDT value must fit pool range
- User must have approved OZONE

**Events**: `UserStaked`

**Gas Cost**: ~200,000

---

#### `createStakeForUser()`
```solidity
function createStakeForUser(
    address _user,
    uint256 _poolId,
    uint256 _ozoneAmount,
    uint256 _usdtValue
) external nonReentrant whenNotPaused
```
**Purpose**: Create stake on behalf of user (called by Presale contract)

**Authorization**: Only authorized stake creators (Presale contract)

**Flow**:
1. Validate caller is authorized
2. Validate pool and amounts
3. Transfer OZONE from caller to contract
4. Create stake entry for user
5. Lock tier, APY, and USDT value

**Events**: `StakeCreatedForUser`

**Gas Cost**: ~180,000

---

#### `claimRewards()`
```solidity
function claimRewards(uint256 _stakeIndex) external nonReentrant
```
**Purpose**: Claim accumulated rewards (default USDT)

**Flow**:
1. Check if 15 days have passed since last claim
2. Calculate available rewards
3. Validate reserves
4. Transfer rewards to user
5. Update stake metadata
6. Auto-burn if reached 300%

**Requirements**:
- Must wait 15 days since last claim
- Must have claimable rewards > 0
- Sufficient reserves

**Events**: `RewardClaimed`, potentially `TokensAutoBurned`

**Gas Cost**: ~120,000 (without auto-burn), ~180,000 (with auto-burn)

---

#### `calculateAvailableRewards()`
```solidity
function calculateAvailableRewards(address _user, uint256 _stakeIndex) 
    public view returns (uint256 claimableRewards, bool shouldAutoBurn)
```
**Purpose**: Calculate current claimable rewards

**Formula**:
```
timeElapsed = current time - lastClaimTime
daysElapsed = timeElapsed / 1 day

dailyReward = (originalAmount × lockedAPY) / 10,000 / 30
totalReward = dailyReward × daysElapsed
totalRewardUSDT = totalReward × ozonePrice / 10^18

maxRewardUSDT = usdtValueAtStake × 30,000 / 10,000 (300%)
remainingReward = maxRewardUSDT - totalClaimedReward

claimableRewards = min(totalRewardUSDT, remainingReward)
shouldAutoBurn = (totalClaimedReward + claimableRewards >= maxRewardUSDT)
```

**Returns**:
- `claimableRewards`: Amount in USDT (6 decimals)
- `shouldAutoBurn`: Whether this claim will trigger auto-burn

**Gas Cost**: ~15,000 (view function)

---

### OzonePresaleV2 Functions

#### `buyAndStake()`
```solidity
function buyAndStake(uint256 _usdtAmount) external nonReentrant whenNotPaused
```
**Purpose**: One-transaction buy OZONE and auto-stake

**Flow**:
```
1. Validate USDT amount (min/max limits)
2. Get current OZONE price from oracle
3. Calculate OZONE amount to buy
4. Determine pool tier based on USDT value
5. Transfer USDT from user to treasury
6. Approve staking contract
7. Call stakingV2.createStakeForUser()
8. Record purchase
9. Update statistics
```

**Gas Breakdown**:
- Price fetch: ~30,000
- USDT transfer: ~50,000
- Approval: ~45,000
- Staking contract call: ~180,000
- State updates: ~50,000
- **Total**: ~355,000 gas

**Events**: `TokensPurchased`, `BuyAndStakeCompleted`

---

#### `getCurrentPrice()`
```solidity
function getCurrentPrice() public view returns (uint256 price)
```
**Purpose**: Get OZONE price from active oracle source

**Logic**:
```solidity
if (priceSource == CHAINLINK) {
    return _getPriceFromChainlink();
} else if (priceSource == DEX_TWAP) {
    return _getPriceFromDEX();
} else {
    return manualOzonePrice;
}
```

**Chainlink Integration**:
```solidity
function _getPriceFromChainlink() private view returns (uint256) {
    (
        /* uint80 roundID */,
        int256 price,
        /* uint256 startedAt */,
        uint256 updatedAt,
        /* uint80 answeredInRound */
    ) = chainlinkPriceFeed.latestRoundData();
    
    // Validate price
    require(price > 0, "Invalid Chainlink price");
    
    // Check staleness (max 1 hour old)
    require(block.timestamp - updatedAt < MAX_PRICE_AGE, "Chainlink price stale");
    
    // Convert from Chainlink decimals (usually 8) to 18 decimals
    uint8 decimals = chainlinkPriceFeed.decimals();
    return uint256(price) * 10**(18 - decimals);
}
```

**Gas Cost**: 
- Manual: ~3,000
- Chainlink: ~35,000
- DEX TWAP: ~50,000 (estimated)

---

## 🧮 Reward Calculation Logic

### Daily Reward Formula

```
Input:
- originalAmount: Initial OZONE staked (18 decimals)
- lockedAPY: APY at stake time (basis points, e.g., 900 = 9%)
- daysElapsed: Days since last claim

Calculation:
dailyReward = (originalAmount × lockedAPY) / 10,000 / 30

Example:
originalAmount = 5,882 OZONE
lockedAPY = 900 (9% monthly)
dailyReward = (5882 × 900) / 10,000 / 30
            = 5,293,800 / 10,000 / 30
            = 17.646 OZONE/day

Convert to USDT:
ozonePrice = 0.85 × 10^18
dailyRewardUSDT = (17.646 × 10^18 × 0.85 × 10^18) / 10^18
                = 14.999 USDT/day (~$15)
```

### Monthly Projection

```
monthlyReward = dailyReward × 30
              = 17.646 × 30
              = 529.38 OZONE/month
              ≈ $450 USDT/month (at $0.85)
```

### Maximum Reward Cap

```
usdtValueAtStake = 5,000 USDT (6 decimals: 5,000,000,000)
maxRewardPercent = 30,000 (300%)

maxRewardUSDT = (5,000,000,000 × 30,000) / 10,000
              = 15,000,000,000 (15,000 USDT with 6 decimals)

Time to reach max:
months = 15,000 / 450 = 33.33 months
days = 33.33 × 30 = 1000 days
```

### Claimable Rewards Calculation

```solidity
// Calculate elapsed time
timeElapsed = block.timestamp - userStake.lastClaimTime;
daysElapsed = timeElapsed / 1 days;

// Calculate total rewards earned
dailyReward = (userStake.originalAmount * userStake.lockedAPY) / 10000 / 30;
totalReward = dailyReward * daysElapsed;

// Convert to USDT value
totalRewardUSDT = (totalReward * ozonePrice) / 10**18;

// Check against max reward
maxRewardUSDT = (userStake.usdtValueAtStake * 30000) / 10000;
remainingRewardUSDT = maxRewardUSDT - userStake.totalClaimedReward;

// Final claimable amount
if (totalRewardUSDT > remainingRewardUSDT) {
    claimableRewards = remainingRewardUSDT;
} else {
    claimableRewards = totalRewardUSDT;
}
```

---

## 🔥 Auto-Burn Mechanism

### Trigger Conditions

Auto-burn occurs when:
```solidity
bool shouldAutoBurn = 
    pool.enableAutoBurn && 
    (userStake.totalClaimedReward + claimableRewards >= maxRewardUSDT);
```

### Burn Process

```solidity
function _autoBurnTokens(uint256 _stakeIndex) private {
    UserStake storage userStake = userStakes[msg.sender][_stakeIndex];
    
    // Get amount to burn (principal)
    uint256 burnAmount = userStake.amount;
    
    // Mark stake as burned and inactive
    userStake.isBurned = true;
    userStake.isActive = false;
    
    // Update global stats
    pools[userStake.poolId].totalStaked -= burnAmount;
    totalTokensBurned += burnAmount;
    activeStakeCount--;
    
    // Transfer to dead address (BURN!)
    ozoneToken.transfer(
        address(0x000000000000000000000000000000000000dEaD), 
        burnAmount
    );
    
    emit TokensAutoBurned(msg.sender, _stakeIndex, burnAmount, userStake.totalClaimedReward);
}
```

### Dead Address

```
Burn Address: 0x000000000000000000000000000000000000dEaD
Why: 
- More visible than 0x0 address
- Tokens provably unrecoverable
- Etherscan shows as "DEAD" tokens
- Industry standard for burns
```

### Economic Impact

```
Example:
User invests: $5,000 USDT
Receives: 5,882 OZONE (at $0.85)
Earns over time: $15,000 USDT (300%)
At month 33:
- Total claimed: $15,000
- Principal burned: 5,882 OZONE 🔥
- Net profit: $10,000 (200%)

Ecosystem benefit:
- Permanent supply reduction
- Deflationary pressure
- Benefits all holders
- Price support mechanism
```

---

## 🤖 Price Oracle Integration

### Price Source Enum

```solidity
enum PriceSource {
    MANUAL,      // 0: Owner updates manually
    CHAINLINK,   // 1: Chainlink oracle
    DEX_TWAP     // 2: DEX time-weighted average
}
```

### Chainlink Integration

#### Setup
```javascript
// BSC Mainnet Chainlink feeds (examples)
const BNB_USD = "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE";
const BTC_USD = "0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf";

// For OZONE (when available)
const OZONE_USD = "0x..."; // To be determined

await presaleV2.setChainlinkPriceFeed(OZONE_USD);
await presaleV2.setPriceSource(1); // PriceSource.CHAINLINK
```

#### Data Validation
```solidity
function _getPriceFromChainlink() private view returns (uint256) {
    require(address(chainlinkPriceFeed) != address(0), "Feed not set");
    
    (
        /* uint80 roundID */,
        int256 price,
        /* uint256 startedAt */,
        uint256 updatedAt,
        /* uint80 answeredInRound */
    ) = chainlinkPriceFeed.latestRoundData();
    
    // Validation 1: Price must be positive
    require(price > 0, "Invalid Chainlink price");
    
    // Validation 2: Data must be fresh (< 1 hour old)
    require(
        block.timestamp - updatedAt < MAX_PRICE_AGE, 
        "Chainlink price stale"
    );
    
    // Convert decimals (Chainlink typically uses 8 decimals)
    uint8 decimals = chainlinkPriceFeed.decimals();
    uint256 priceWithDecimals = uint256(price) * 10**(18 - decimals);
    
    return priceWithDecimals;
}
```

### Manual Price Update

#### Safety Bounds
```solidity
// Set price bounds
minAllowedPrice: 0.01 * 10^18  ($0.01)
maxAllowedPrice: 100 * 10^18   ($100)
maxPriceChangePercent: 2000    (20%)

// Update price
function updateManualPrice(uint256 _newPrice) external onlyOwner {
    // Check bounds
    require(_newPrice >= minAllowedPrice, "Price below minimum");
    require(_newPrice <= maxAllowedPrice, "Price above maximum");
    
    // Check max change percentage
    if (manualOzonePrice > 0) {
        uint256 priceDiff = abs(_newPrice - manualOzonePrice);
        uint256 changePercent = (priceDiff * 10000) / manualOzonePrice;
        require(changePercent <= maxPriceChangePercent, "Price change too large");
    }
    
    uint256 oldPrice = manualOzonePrice;
    manualOzonePrice = _newPrice;
    lastPriceUpdate = block.timestamp;
    
    emit ManualPriceUpdated(oldPrice, _newPrice, block.timestamp);
}
```

#### Automation Script
```javascript
// Automated price update script
const cron = require('node-cron');
const axios = require('axios');

// Run every 15 minutes
cron.schedule('*/15 * * * *', async () => {
    try {
        // Fetch from Digifinex
        const response = await axios.get('https://openapi.digifinex.com/v3/ticker?symbol=ozone_usdt');
        const price = response.data.ticker.last;
        
        // Update contract
        const tx = await presaleV2.updateManualPrice(
            ethers.utils.parseEther(price.toString())
        );
        await tx.wait();
        
        console.log(`Price updated to $${price}`);
    } catch (error) {
        console.error('Price update failed:', error);
    }
});
```

---

## 🔄 Upgrade Mechanism

### UUPS Pattern

```
Traditional Proxy Pattern:
User → Proxy Contract → Implementation Contract
        (Storage)         (Logic)

Upgrade:
Owner calls: proxy.upgradeTo(newImplementation)
```

### Upgrade Authorization

```solidity
function _authorizeUpgrade(address newImplementation) 
    internal override onlyOwner 
{
    emit ContractUpgraded(newImplementation, block.timestamp);
}
```

### Safe Upgrade Process

```javascript
// 1. Deploy new implementation
const StakingV3 = await ethers.getContractFactory("OzoneStakingV3");
const newImpl = await StakingV3.deploy();
await newImpl.deployed();

// 2. Verify new implementation
await hre.run("verify:verify", {
    address: newImpl.address,
    constructorArguments: []
});

// 3. Test on testnet first!
const testnetProxy = StakingV2.attach(testnetProxyAddress);
await upgrades.upgradeProxy(testnetProxy.address, StakingV3);

// 4. Audit new implementation
// ... external audit ...

// 5. Upgrade mainnet (after approval)
const mainnetProxy = StakingV2.attach(mainnetProxyAddress);
await upgrades.upgradeProxy(mainnetProxy.address, StakingV3);

// 6. Verify upgrade succeeded
const newVersion = await mainnetProxy.getVersion();
console.log("New version:", newVersion); // Should be "3.0.0-UUPS"
```

### Storage Safety

⚠️ **CRITICAL**: Never change storage layout in upgrades!

**Safe Upgrade**:
```solidity
// V2
uint256 public ozonePrice;
uint256 public totalStaked;

// V3 (SAFE - only adding new variables)
uint256 public ozonePrice;
uint256 public totalStaked;
uint256 public newFeature; // ✅ OK
```

**Unsafe Upgrade**:
```solidity
// V2
uint256 public ozonePrice;
uint256 public totalStaked;

// V3 (UNSAFE - changing order)
uint256 public totalStaked;    // ❌ WRONG!
uint256 public ozonePrice;     // ❌ WRONG!
uint256 public newFeature;
```

---

## ⚡ Gas Optimization

### Optimizations Implemented

1. **Immutable Variables** (where possible)
```solidity
// Saves ~20,000 gas per read
IERC20 public immutable ozoneToken; // Can't use in upgradeable
IERC20 public ozoneToken;           // Used instead
```

2. **Packed Structs**
```solidity
struct UserStake {
    uint256 amount;        // slot 0
    uint256 originalAmount;// slot 1
    uint256 usdtValueAtStake; // slot 2
    uint256 poolId;        // slot 3
    // ... optimized packing
}
```

3. **Cache Array Length**
```solidity
// Instead of:
for (uint256 i = 0; i < array.length; i++) { ... }

// Use:
uint256 length = array.length;
for (uint256 i = 0; i < length; i++) { ... }
```

4. **Short-circuit Logic**
```solidity
// Cheaper checks first
if (amount == 0 || !isActive || isBurned) return (0, false);
```

5. **Event Indexing**
```solidity
// Indexed parameters for efficient filtering
event TokensPurchased(
    address indexed buyer,  // indexed
    uint256 usdtAmount,     // not indexed
    uint256 ozoneAmount,    // not indexed
    uint256 indexed poolId  // indexed
);
```

### Gas Costs Summary

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Deploy StakingV2 | ~3,500,000 | Includes proxy + 5 pools |
| Deploy PresaleV2 | ~2,800,000 | Includes proxy |
| stake() | ~200,000 | First stake more expensive |
| buyAndStake() | ~355,000 | Includes price fetch |
| claimRewards() | ~120,000 | Without auto-burn |
| claimRewards() (with burn) | ~180,000 | Includes burn |
| unstake() | ~80,000 | Early exit |
| Price update (manual) | ~45,000 | |
| Price fetch (Chainlink) | ~35,000 | |

---

## 🚨 Error Codes

### Common Errors

```solidity
// OzoneStakingV2
"Invalid pool" - Pool ID out of range
"Pool not active" - Pool has been deactivated
"Amount must be greater than 0" - Zero stake amount
"Below minimum stake for this pool" - USDT value too low
"Above maximum stake for this pool" - USDT value too high
"Transfer failed" - OZONE transfer failed
"Not authorized to create stakes" - Caller not authorized
"Invalid stake index" - Stake doesn't exist
"Cannot claim yet - must wait 15 days" - Claim interval not passed
"No rewards available" - Nothing to claim
"Insufficient USDT reserves" - Not enough USDT for rewards
"Insufficient OZONE reserves" - Not enough OZONE for rewards
"Stake is not active" - Stake already closed/burned

// OzonePresaleV2
"Below minimum purchase" - USDT amount < minPurchaseUSDT
"Above maximum purchase" - USDT amount > maxPurchaseUSDT
"Invalid price" - Oracle returned 0 or negative
"Amount too small" - Calculated OZONE amount is 0
"Exceeds remaining supply" - Not enough OZONE left
"USDT transfer failed" - Payment failed
"Approval failed" - OZONE approval failed
"Chainlink feed not set" - No oracle configured
"Chainlink price stale" - Oracle data too old
"Price below minimum" - Price update too low
"Price above maximum" - Price update too high
"Price change too large" - Price changed > 20%
```

### Debugging

```javascript
// Enable detailed error messages
await contract.callStatic.functionName(...params);
// Returns detailed revert reason before sending transaction

// Example
try {
    await presaleV2.callStatic.buyAndStake(amount);
    // If no error, proceed with actual transaction
    await presaleV2.buyAndStake(amount);
} catch (error) {
    console.error("Transaction would fail:", error.message);
}
```

---

## 🔍 Testing Checklist

### Unit Tests

```javascript
describe("OzoneStakingV2", function() {
    it("Should initialize correctly", async function() { ... });
    it("Should create stake with correct tier", async function() { ... });
    it("Should calculate rewards correctly", async function() { ... });
    it("Should enforce 15-day claim interval", async function() { ... });
    it("Should auto-burn at 300%", async function() { ... });
    it("Should prevent unauthorized stake creation", async function() { ... });
    it("Should handle dual rewards correctly", async function() { ... });
});

describe("OzonePresaleV2", function() {
    it("Should buy and stake in one transaction", async function() { ... });
    it("Should determine correct pool tier", async function() { ... });
    it("Should fetch price from Chainlink", async function() { ... });
    it("Should enforce price bounds", async function() { ... });
    it("Should track user purchases", async function() { ... });
});
```

### Integration Tests

```javascript
describe("Integration", function() {
    it("Should complete full user journey", async function() {
        // 1. Buy and stake via presale
        // 2. Wait 15 days
        // 3. Claim rewards
        // 4. Repeat until 300%
        // 5. Verify auto-burn
    });
});
```

---

**Last Updated**: December 2, 2025  
**Version**: 2.0.0-UUPS  
**Authors**: OZONE Development Team

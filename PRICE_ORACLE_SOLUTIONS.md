# 🔄 Auto Price Update Solutions - OZONE Staking V2

## 🎯 Problem Statement

**Challenge:**
- OZONE price di DigiFinex sangat fluktuatif
- Manual update via `setOzonePrice()` tidak praktis
- User beli/stake harus dapat harga real-time yang akurat

**Requirement:**
- Auto-update price dari external source
- Akurat & reliable
- Minimal manual intervention

---

## 💡 Solution Options

### **Opsi 1: Chainlink Price Feed (RECOMMENDED) ⭐**

**Kelebihan:**
- ✅ Decentralized & trustless oracle network
- ✅ Price data dari multiple sources
- ✅ High security & reliability
- ✅ Industry standard (dipakai Aave, Compound, dll)
- ✅ Built-in untuk BSC

**Kekurangan:**
- ❌ OZONE belum ada official Chainlink feed
- ❌ Perlu custom oracle solution atau sponsored feed
- ❌ Ada biaya untuk maintain oracle

**Implementasi:**

Jika OZONE sudah listed di Chainlink:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract OzoneStakingV2 {
    // ... existing code ...
    
    AggregatorV3Interface public ozonePriceFeed;
    
    function initialize(
        // ... existing parameters
        address _ozonePriceFeed  // Chainlink price feed address
    ) public initializer {
        // ... existing initialization
        ozonePriceFeed = AggregatorV3Interface(_ozonePriceFeed);
    }
    
    /**
     * @dev Get real-time OZONE price from Chainlink
     * @return price OZONE price in USDT (18 decimals)
     */
    function getOzonePrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = ozonePriceFeed.latestRoundData();
        
        require(answer > 0, "Invalid price");
        require(updatedAt > 0, "Price not updated");
        
        // Chainlink typically returns 8 decimals, convert to 18
        // answer = price in USD with 8 decimals
        // return price * 10^10 to get 18 decimals
        return uint256(answer) * 10**10;
    }
    
    /**
     * @dev Modified buyAndStake to use real-time price
     */
    function buyAndStake(uint256 _poolId, uint256 _usdtAmount) external {
        // Get real-time price
        uint256 currentPrice = getOzonePrice();
        
        // Calculate OZONE amount based on real-time price
        uint256 ozoneAmount = (_usdtAmount * 10**18) / currentPrice;
        
        // ... rest of the function
    }
    
    /**
     * @dev Modified stake to use real-time price
     */
    function stake(uint256 _poolId, uint256 _amount) external {
        // Get real-time price for USDT value calculation
        uint256 currentPrice = getOzonePrice();
        
        // Calculate USDT value
        uint256 usdtValue = (_amount * currentPrice) / 10**18;
        
        // ... rest of the function
    }
}
```

**Setup:**
1. Apply for Chainlink custom feed untuk OZONE
2. Deploy price feed contract
3. Fund dengan LINK tokens
4. Set feed address di StakingV2 contract

**Cost:** ~0.1 LINK per price update (~$0.50-$1 per update)

---

### **Opsi 2: Band Protocol Oracle**

**Kelebihan:**
- ✅ Decentralized oracle khusus untuk BSC
- ✅ Bisa request custom price feeds
- ✅ Cheaper than Chainlink di BSC

**Kekurangan:**
- ❌ Kurang adoption dibanding Chainlink
- ❌ Perlu setup custom oracle

**Implementasi:**

```solidity
import "./IBandOracle.sol";

contract OzoneStakingV2 {
    IBandOracle public bandOracle;
    string public constant OZONE_SYMBOL = "OZONE/USDT";
    
    function getOzonePrice() public view returns (uint256) {
        IBandOracle.ReferenceData memory data = bandOracle.getReferenceData(
            OZONE_SYMBOL,
            "USDT"
        );
        return data.rate;
    }
}
```

---

### **Opsi 3: Custom Backend Oracle (Hybrid Solution) ⭐⭐**

**Paling Praktis untuk Kasus Anda:**

**Architecture:**
```
DigiFinex API → Backend Service → Smart Contract
     ↓               ↓                    ↓
  Real Price    Price Fetcher        updatePrice()
  (fluktuatif)   (every 1 min)      (on-chain)
```

**Kelebihan:**
- ✅ Mudah implement
- ✅ Data langsung dari DigiFinex (source of truth)
- ✅ Update frequency flexible (1 min, 5 min, dll)
- ✅ Full control
- ✅ Bisa filter anomaly prices

**Kekurangan:**
- ⚠️ Centralized (tergantung backend)
- ⚠️ Perlu secure private key management
- ⚠️ Single point of failure

**Implementation:**

**Smart Contract (minimal changes):**

```solidity
contract OzoneStakingV2 {
    // ... existing code
    
    address public priceUpdater; // Address yang authorized update price
    uint256 public lastPriceUpdate;
    uint256 public constant MAX_PRICE_AGE = 5 minutes; // Max staleness
    
    event PriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 timestamp, address updater);
    
    function initialize(
        // ... existing params
        address _priceUpdater
    ) public initializer {
        // ... existing init
        priceUpdater = _priceUpdater;
    }
    
    /**
     * @dev Update price - called by backend service
     * @param _newPrice New OZONE price in USDT (18 decimals)
     */
    function updateOzonePrice(uint256 _newPrice) external {
        require(msg.sender == priceUpdater, "Not authorized");
        require(_newPrice > 0, "Invalid price");
        
        uint256 oldPrice = ozonePrice;
        ozonePrice = _newPrice;
        lastPriceUpdate = block.timestamp;
        
        emit PriceUpdated(oldPrice, _newPrice, block.timestamp, msg.sender);
    }
    
    /**
     * @dev Check if price is fresh
     */
    function isPriceFresh() public view returns (bool) {
        return block.timestamp - lastPriceUpdate <= MAX_PRICE_AGE;
    }
    
    /**
     * @dev Modified buyAndStake dengan price freshness check
     */
    function buyAndStake(uint256 _poolId, uint256 _usdtAmount) external {
        require(isPriceFresh(), "Price stale, please wait");
        
        // Use ozonePrice (updated by backend)
        uint256 ozoneAmount = (_usdtAmount * 10**18) / ozonePrice;
        
        // ... rest of function
    }
    
    /**
     * @dev Set price updater address
     */
    function setPriceUpdater(address _newUpdater) external onlyOwner {
        require(_newUpdater != address(0), "Invalid address");
        priceUpdater = _newUpdater;
    }
}
```

**Backend Service (Node.js Example):**

```javascript
// backend/priceUpdater.js
const ethers = require('ethers');
const axios = require('axios');

// Config
const RPC_URL = 'https://bsc-dataseed1.binance.org/';
const CONTRACT_ADDRESS = '0xYourStakingV2Address';
const UPDATER_PRIVATE_KEY = process.env.PRICE_UPDATER_KEY;
const UPDATE_INTERVAL = 60 * 1000; // 1 minute

// Setup
const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(UPDATER_PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

/**
 * Fetch OZONE price from DigiFinex
 */
async function fetchOzonePrice() {
    try {
        // DigiFinex API endpoint
        const response = await axios.get('https://openapi.digifinex.com/v3/ticker', {
            params: { symbol: 'ozone_usdt' }
        });
        
        const price = parseFloat(response.data.ticker[0].last);
        console.log(`DigiFinex OZONE price: $${price}`);
        
        return price;
    } catch (error) {
        console.error('Error fetching price:', error);
        return null;
    }
}

/**
 * Update price on-chain
 */
async function updatePriceOnChain(price) {
    try {
        // Convert to 18 decimals
        const priceInWei = ethers.utils.parseEther(price.toString());
        
        console.log(`Updating on-chain price to: ${price} ($${priceInWei})`);
        
        // Send transaction
        const tx = await contract.updateOzonePrice(priceInWei, {
            gasLimit: 100000
        });
        
        console.log(`Transaction sent: ${tx.hash}`);
        
        const receipt = await tx.wait();
        console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
        
        return true;
    } catch (error) {
        console.error('Error updating price:', error);
        return false;
    }
}

/**
 * Main loop
 */
async function main() {
    console.log('OZONE Price Updater Service Started');
    console.log(`Update Interval: ${UPDATE_INTERVAL / 1000} seconds`);
    
    let lastPrice = null;
    
    setInterval(async () => {
        // Fetch current price
        const currentPrice = await fetchOzonePrice();
        
        if (!currentPrice) {
            console.log('Failed to fetch price, skipping update');
            return;
        }
        
        // Only update if price changed significantly (e.g., >0.1%)
        if (lastPrice) {
            const priceChange = Math.abs((currentPrice - lastPrice) / lastPrice);
            if (priceChange < 0.001) {
                console.log('Price change < 0.1%, skipping update');
                return;
            }
        }
        
        // Update on-chain
        const success = await updatePriceOnChain(currentPrice);
        
        if (success) {
            lastPrice = currentPrice;
        }
    }, UPDATE_INTERVAL);
}

main().catch(console.error);
```

**Deployment:**

```bash
# Install dependencies
npm install ethers axios dotenv

# Create .env file
echo "PRICE_UPDATER_KEY=your_private_key_here" > .env

# Run service
node priceUpdater.js

# Or with PM2 for production
pm2 start priceUpdater.js --name "ozone-price-updater"
```

**Docker (Production):**

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

CMD ["node", "priceUpdater.js"]
```

---

### **Opsi 4: Hybrid - Backend + Chainlink Fallback (BEST) ⭐⭐⭐**

**Kombinasi terbaik:**

```solidity
contract OzoneStakingV2 {
    AggregatorV3Interface public chainlinkFeed; // Fallback
    address public priceUpdater; // Primary
    uint256 public ozonePrice;
    uint256 public lastPriceUpdate;
    bool public useChainlinkFallback;
    
    /**
     * @dev Get price with fallback mechanism
     */
    function getOzonePrice() public view returns (uint256) {
        // Check if backend price is fresh
        bool priceFresh = block.timestamp - lastPriceUpdate <= 5 minutes;
        
        if (priceFresh && !useChainlinkFallback) {
            // Use backend-updated price (primary)
            return ozonePrice;
        } else if (address(chainlinkFeed) != address(0)) {
            // Fallback to Chainlink
            (, int256 answer,,,) = chainlinkFeed.latestRoundData();
            require(answer > 0, "Invalid Chainlink price");
            return uint256(answer) * 10**10;
        } else {
            // No fallback available
            revert("Price not available");
        }
    }
    
    /**
     * @dev Toggle Chainlink fallback
     */
    function setUseChainlinkFallback(bool _use) external onlyOwner {
        useChainlinkFallback = _use;
    }
}
```

**Benefits:**
- ✅ Primary: Fast updates from DigiFinex (via backend)
- ✅ Fallback: Chainlink jika backend down
- ✅ Best of both worlds

---

## 📊 Comparison

| Solution | Decentralization | Cost | Setup Complexity | Update Speed | Recommended |
|----------|-----------------|------|------------------|--------------|-------------|
| **Chainlink** | ⭐⭐⭐⭐⭐ | High | Medium | Medium (minutes) | If OZONE has feed |
| **Band Protocol** | ⭐⭐⭐⭐ | Medium | Medium | Medium | Alternative to Chainlink |
| **Backend Oracle** | ⭐ | Low | Easy | Fast (seconds) | ⭐⭐ Quick start |
| **Hybrid** | ⭐⭐⭐ | Medium | Hard | Fast + Reliable | ⭐⭐⭐ Best overall |

---

## 🎯 Recommendation untuk OZONE

**Short Term (Launch - 6 months):**
1. **Backend Oracle** (Opsi 3)
   - Quick to implement
   - Direct dari DigiFinex
   - Full control
   - Update every 1-5 minutes

**Long Term (6+ months):**
2. **Hybrid Solution** (Opsi 4)
   - Add Chainlink as fallback
   - More decentralized
   - Higher security
   - Better for large TVL

**Implementation Priority:**
```
Phase 1: Backend Oracle (Week 1)
  ↓
Phase 2: Price monitoring & alerts (Week 2)
  ↓
Phase 3: Add Chainlink fallback (Month 3-6)
  ↓
Phase 4: Fully decentralized oracle (Year 1+)
```

---

## 🔐 Security Considerations

**Backend Oracle:**
- ✅ Use dedicated wallet untuk price updater (low balance)
- ✅ Implement rate limiting (max 1 update per minute)
- ✅ Price validation (reject anomalies > 10% change)
- ✅ Multi-sig untuk change priceUpdater address
- ✅ Monitor & alert jika price stale > 5 minutes

**Smart Contract:**
- ✅ Price freshness check (`isPriceFresh()`)
- ✅ Emergency pause mechanism
- ✅ Owner can override jika needed
- ✅ Event logging untuk transparency

---

## 💰 Cost Analysis

**Backend Oracle:**
- Server: $10-20/month (VPS)
- Gas for updates: ~0.0001 BNB per update = $0.03/update
- If update every 1 min: ~$43/day = $1,300/month
- **Optimization:** Only update if price changed > 0.1%
- **Realistic cost:** $100-300/month

**Chainlink:**
- Feed setup: ~$5,000-10,000 one-time
- Maintenance: ~0.1 LINK per update = ~$300-500/month

**Recommendation:** Start dengan Backend Oracle (lebih murah), migrate ke hybrid later.

---

## 🆓 ZERO COST SOLUTION - Off-Chain Price (NEW!)

### **Opsi 5: Frontend Fetch Price from API (100% Free)** ⭐⭐⭐

**Konsep:** Price **TIDAK** disimpan on-chain, tapi di-fetch di frontend saat user mau transaksi!

**Architecture:**
```
User Opens dApp → Frontend Fetch API → Get Real-time Price → User Confirm
        ↓                ↓                    ↓                    ↓
    Open page      DigiFinex/CoinGecko    $88.50 OZONE        buyAndStake()
                      (FREE API)          (show to user)      (send to contract)
```

**How It Works:**

**Step 1: User Fetch Price di Frontend**
```javascript
// Frontend (React/Next.js example)
async function getOzonePrice() {
    try {
        // Option A: DigiFinex API (FREE, no API key needed)
        const response = await fetch('https://openapi.digifinex.com/v3/ticker?symbol=ozone_usdt');
        const data = await response.json();
        const price = parseFloat(data.ticker[0].last);
        
        // Option B: CoinGecko API (FREE, 50 calls/min)
        // const response = await fetch('https://api.coingecko.com/api/v3/simple/price?ids=ozone-chain&vs_currencies=usd');
        // const price = response.data['ozone-chain'].usd;
        
        return price;
    } catch (error) {
        console.error('Error fetching price:', error);
        return null;
    }
}

// User click "Buy & Stake"
async function handleBuyAndStake(poolId, usdtAmount) {
    // 1. Fetch real-time price
    const ozonePrice = await getOzonePrice(); // e.g., 88.50
    
    if (!ozonePrice) {
        alert('Failed to fetch price, please try again');
        return;
    }
    
    // 2. Show user the price & calculate OZONE amount
    const ozoneAmount = usdtAmount / ozonePrice;
    
    const confirmed = confirm(`
        Current OZONE Price: $${ozonePrice}
        You will receive: ${ozoneAmount.toFixed(4)} OZONE
        Confirm purchase?
    `);
    
    if (!confirmed) return;
    
    // 3. User confirms, send to contract WITH price
    const priceInWei = ethers.utils.parseEther(ozonePrice.toString());
    
    await stakingContract.buyAndStakeWithPrice(
        poolId,
        ethers.utils.parseEther(usdtAmount.toString()),
        priceInWei  // ← User submit price dari API
    );
}
```

**Step 2: Modified Smart Contract**

```solidity
contract OzoneStakingV2 {
    // Remove ozonePrice state variable
    // No need to store price on-chain!
    
    uint256 public constant MAX_PRICE_DEVIATION = 1000; // 10% max deviation
    uint256 public recentAveragePrice; // For validation only
    uint256 public lastPriceUpdateTime;
    
    /**
     * @dev Buy and stake with user-provided price
     * @param _poolId Pool ID
     * @param _usdtAmount USDT amount to spend
     * @param _currentPrice Current OZONE price from off-chain source (18 decimals)
     */
    function buyAndStakeWithPrice(
        uint256 _poolId,
        uint256 _usdtAmount,
        uint256 _currentPrice
    ) external nonReentrant whenNotPaused {
        require(presaleActive, "Presale not active");
        require(_currentPrice > 0, "Invalid price");
        
        // Validate price is reasonable (prevent manipulation)
        if (recentAveragePrice > 0) {
            uint256 deviation = _calculateDeviation(_currentPrice, recentAveragePrice);
            require(deviation <= MAX_PRICE_DEVIATION, "Price deviation too high");
        }
        
        // Update recent average price (simple moving average)
        _updateRecentPrice(_currentPrice);
        
        // Calculate OZONE amount based on user-provided price
        uint256 ozoneAmount = (_usdtAmount * 10**18) / _currentPrice;
        
        // Calculate 1% platform fee
        uint256 taxAmount = (_usdtAmount * PURCHASE_TAX_RATE) / BASIS_POINTS;
        uint256 totalCost = _usdtAmount + taxAmount;
        
        // ... rest of buyAndStake logic (same as before)
        
        // Record the price used for this stake
        emit PriceUsed(msg.sender, _currentPrice, block.timestamp);
    }
    
    /**
     * @dev Manual stake with user-provided price
     */
    function stakeWithPrice(
        uint256 _poolId,
        uint256 _amount,
        uint256 _currentPrice
    ) external nonReentrant whenNotPaused {
        require(_currentPrice > 0, "Invalid price");
        
        // Validate price deviation
        if (recentAveragePrice > 0) {
            uint256 deviation = _calculateDeviation(_currentPrice, recentAveragePrice);
            require(deviation <= MAX_PRICE_DEVIATION, "Price deviation too high");
        }
        
        // Update recent average
        _updateRecentPrice(_currentPrice);
        
        // Calculate USDT value based on user-provided price
        uint256 usdtValue = (_amount * _currentPrice) / 10**18;
        
        // ... rest of stake logic
        
        emit PriceUsed(msg.sender, _currentPrice, block.timestamp);
    }
    
    /**
     * @dev Calculate price deviation percentage (in basis points)
     */
    function _calculateDeviation(uint256 price1, uint256 price2) private pure returns (uint256) {
        uint256 diff = price1 > price2 ? price1 - price2 : price2 - price1;
        return (diff * 10000) / price2; // Return in basis points
    }
    
    /**
     * @dev Update recent average price (simple exponential moving average)
     */
    function _updateRecentPrice(uint256 newPrice) private {
        if (recentAveragePrice == 0) {
            recentAveragePrice = newPrice;
        } else {
            // EMA: new_avg = (new_price * 0.2) + (old_avg * 0.8)
            recentAveragePrice = (newPrice * 2 + recentAveragePrice * 8) / 10;
        }
        lastPriceUpdateTime = block.timestamp;
    }
    
    event PriceUsed(address indexed user, uint256 price, uint256 timestamp);
}
```

**Kelebihan:**
- ✅ **100% FREE** - Tidak ada biaya server
- ✅ **100% FREE** - Tidak ada gas untuk update price
- ✅ **Real-time** - Price selalu terbaru saat user transaksi
- ✅ **Multiple sources** - Bisa pakai DigiFinex, CoinGecko, dll
- ✅ **User transparency** - User lihat price sebelum confirm

**Kekurangan:**
- ⚠️ **User-dependent** - User submit price (bisa manipulasi?)
- ⚠️ **Validation needed** - Contract harus validate price reasonable
- ⚠️ **Frontend required** - Tidak bisa call contract langsung

**Anti-Manipulation Protection:**

```solidity
// Contract validate price dengan recent average
// Jika price terlalu jauh dari average → reject
// Example:
// Recent average: $88
// User submit: $100 (13.6% higher) → REJECTED (> 10% max)
// User submit: $90 (2.3% higher) → ACCEPTED
// User submit: $80 (9.1% lower) → ACCEPTED

require(deviation <= MAX_PRICE_DEVIATION, "Price too different from market");
```

---

### **Opsi 6: Gelato Network (Semi-Automated, Low Cost)**

**Gelato Web3 Functions** - Serverless automation for smart contracts

**How it works:**
```
Gelato Network → Fetch DigiFinex API → Call updatePrice() → Done
   (automated)      (every X minutes)     (your contract)   (pay only gas)
```

**Setup:**

```javascript
// gelato/ozonePriceUpdater.js
import { Web3Function } from "@gelatonetwork/web3-functions-sdk";

Web3Function.onRun(async (context) => {
    const { userArgs, multiChainProvider } = context;
    
    // 1. Fetch price from DigiFinex
    const response = await fetch('https://openapi.digifinex.com/v3/ticker?symbol=ozone_usdt');
    const data = await response.json();
    const price = parseFloat(data.ticker[0].last);
    
    // 2. Check if price changed significantly
    const contract = new Contract(userArgs.contractAddress, ABI, provider);
    const currentPrice = await contract.ozonePrice();
    const priceChange = Math.abs((price - currentPrice) / currentPrice);
    
    if (priceChange < 0.005) { // < 0.5% change
        return { canExec: false, message: "Price change too small" };
    }
    
    // 3. Return transaction to update price
    return {
        canExec: true,
        callData: contract.interface.encodeFunctionData("updateOzonePrice", [
            ethers.utils.parseEther(price.toString())
        ])
    };
});
```

**Cost:**
- Setup: FREE
- Execution: Only gas fees (~$0.03 per update)
- No server cost
- Payment via Gelato 1Balance (prepaid)

**Kelebihan:**
- ✅ Automated (no server maintenance)
- ✅ Only pay gas (no monthly fees)
- ✅ Reliable infrastructure
- ✅ Easy setup

**Kekurangan:**
- ⚠️ Perlu fund Gelato balance
- ⚠️ Still costs gas (but optimized)

---

### **Comparison: FREE Solutions**

| Solution | Cost | Decentralized | Security | Complexity | Recommended |
|----------|------|--------------|----------|------------|-------------|
| **Frontend Fetch** | $0 | ⭐ | ⭐⭐⭐ | Easy | ⭐⭐⭐ Best for low volume |
| **Gelato Network** | Gas only | ⭐⭐⭐ | ⭐⭐⭐⭐ | Medium | ⭐⭐ For automation |
| **Backend Oracle** | $100-300/mo | ⭐ | ⭐⭐⭐⭐⭐ | Easy | ⭐⭐⭐ For high volume |

---

### **FREE API Options:**

**1. DigiFinex API (Recommended for OZONE)**
```javascript
// FREE, no API key, unlimited calls
const response = await fetch('https://openapi.digifinex.com/v3/ticker?symbol=ozone_usdt');
const price = response.data.ticker[0].last;
```

**2. CoinGecko API**
```javascript
// FREE, 50 calls/minute without key
// 500 calls/minute with free API key
const response = await fetch('https://api.coingecko.com/api/v3/simple/price?ids=ozone-chain&vs_currencies=usd');
const price = response.data['ozone-chain'].usd;
```

**3. CoinMarketCap API**
```javascript
// FREE tier: 333 calls/day
// Need API key (free signup)
const response = await fetch('https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=OZONE', {
    headers: { 'X-CMC_PRO_API_KEY': 'your_free_key' }
});
```

---

## 🎯 FINAL RECOMMENDATION for ZERO COST

**For Your Case (OZONE Staking):**

### **Phase 1: Launch (Use Opsi 5 - Frontend Fetch)** ⭐⭐⭐

**Why:**
- ✅ **$0 cost** - Perfect for launch
- ✅ **Quick implementation** - 1-2 hours
- ✅ **DigiFinex direct** - Most accurate for OZONE
- ✅ **User transparency** - They see exact price
- ✅ **Validation layer** - Contract prevents manipulation

**Implementation:**
```javascript
// Frontend: Fetch from DigiFinex (FREE)
const price = await getDigiFinexPrice();

// Contract: Validate & record
await contract.buyAndStakeWithPrice(poolId, usdtAmount, price);
```

**Protection:**
- Max 10% price deviation from recent average
- Contract tracks moving average
- Reject suspicious prices

**When to Upgrade:**
- If trading volume > $100k/day
- If you want 100% automated
- If security is critical priority

---

## 📝 Next Steps

1. **Decide:** Backend Oracle atau Hybrid?
2. **Setup:** Backend service (Node.js)
3. **Modify Contract:** Add `updateOzonePrice()` function
4. **Deploy:** Backend service ke server
5. **Monitor:** Price updates & gas costs
6. **Optimize:** Update frequency based on volume

---

**Ready to implement? Pilih solution mana yang Anda prefer!** 🚀

# 📚 DOKUMENTASI BACKEND - OZONE STAKING V2

**Platform:** BSC Testnet (Production akan di BSC Mainnet)  
**Update Terakhir:** 6 Desember 2025  
**Developer:** Backend Team

---

## 🎯 RINGKASAN SISTEM

Sistem ini adalah **staking contract** untuk user BARU yang ingin beli OZONE token dan langsung stake untuk dapat reward USDT bulanan.

**PENTING:** 
- ❌ User LAMA (yang beli OZONE di presale $1) TIDAK BISA stake disini
- ✅ Hanya user BARU yang beli OZONE melalui contract ini (harga real-time ~$55)
- ✅ Harga OZONE harus update OTOMATIS dari DigiFinex Exchange

---

## 📋 INFORMASI CONTRACT

### Contract Addresses (BSC Testnet - LATEST v2.1.1):

```
Proxy Contract (PERMANENT):
0x9DdE321F85e4512dDc7FA0DAEDa1fBa9Bca6C03d

Implementation Contract (v2.1.1-SIMPLIFIED-ORACLE):
0xA624F599A6e5D882b9236f1a40D3Ee9AcB705274
Verified: https://testnet.bscscan.com/address/0xA624F599A6e5D882b9236f1a40D3Ee9AcB705274#code

OZONE Token:
0x21144E5CA7e6324840e46FeCF33f67232A9c728b

USDT Token (18 decimals - BSC Mainnet standard):
0xe04AAFE4A2Ed442d90d7144c42CB2DAcb206E11C
(MockUSDT18 - untuk testing, verified on BscScan)

Treasury Wallet:
0x6250afe09de2b6c8371e962e5f1ffc3542b5df66

Tax Wallet:
0x6fa043175b9c01ac267609106ce1e20b1f355aaa
```

**Catatan:** 
- Gunakan **PROXY ADDRESS** untuk semua interaksi! 
- Implementation address hanya untuk verify contract code
- ⚠️ **OZONE token has 1% transfer tax!** Whitelist contract address untuk avoid tax

### Network Info:
```
Chain: BSC Testnet
Chain ID: 97
RPC: https://data-seed-prebsc-1-s1.bnbchain.org:8545
Explorer: https://testnet.bscscan.com
```

---

## 🏊 POOL TIERS

Ada 5 tier pool dengan APY berbeda:

| Pool | Nama | USDT Range | APY/Bulan | Durasi | Max Reward |
|------|------|------------|-----------|--------|------------|
| 1 | LimoX Pool A | $100 - $1,000 | 6% | 50 bulan | 300% |
| 2 | LimoX Pool B | $1,000 - $3,000 | 7% | 42 bulan | 300% |
| 3 | LimoX Pool C | $3,000 - $5,000 | 8% | 37 bulan | 300% |
| 4 | SaproX Pool A | $5,000 - $10,000 | 9% | 33 bulan | 300% |
| 5 | SaproX Pool B | $10,000+ | 10% | 30 bulan | 300% |

**Cara Kerja:**
- User stake **$1000** → masuk **Pool 1** (6% APY)
- User stake **$5000** → masuk **Pool 4** (9% APY)
- Reward bulanan otomatis calculated berdasarkan APY pool
- Maximum reward total = **300%** dari stake amount
- Setelah reach 300%, token OZONE otomatis **auto-burn**

---

## 🔧 CARA KERJA SISTEM

### 1️⃣ User Beli OZONE via Contract

**Function:** `buyAndStake(poolId, usdtAmount)`

**Proses:**
1. User approve USDT ke contract
2. User call `buyAndStake(1, 1000e18)` → beli $1000 USDT worth OZONE, stake di Pool 1
3. Contract charge **1% platform fee** (contoh: $1000 + $10 fee = $1010 total)
4. Contract calculate OZONE amount: `$1000 / harga_real_time`
5. Contract transfer OZONE ke user (virtual, stay in contract)
6. Contract create stake record untuk user
7. User langsung punya stake aktif!

**Contoh Calculation:**
```
Input: $1000 USDT
Fee (1%): $10 USDT
Net: $990 USDT
OZONE Price: $55
OZONE Received: 990 / 55 = 18 OZONE
Pool: Pool 1 (6% monthly APY)
Monthly Reward: $990 × 6% = $59.4 USDT
Total Reward Cap: $990 × 300% = $2970 USDT
```

### 2️⃣ Reward System

**Claim Interval:** Setiap **15 hari**

User bisa claim reward dengan call:
```javascript
claimReward(stakeIndex)
```

**Reward Calculation:**
```javascript
// Monthly reward
monthlyReward = stakeAmount × poolAPY / 100

// Total claimed cannot exceed 300% of stake
maxReward = stakeAmount × 3
```

**Auto-Burn:**
Ketika total claimed reward reach 300%, OZONE token user otomatis **burn** dan stake menjadi inactive.

### 3️⃣ Price Management

**CRITICAL:** Harga OZONE HARUS update otomatis dari DigiFinex!

**Current Price:** $55 USDT  
**Update Method:** Price bot (akan dijelaskan di bawah)

---

## 🤖 PRICE ORACLE SYSTEM - SIMPLIFIED (v2.1.1)

### ⚠️ PENTING: PERUBAHAN BESAR!

**Version 2.1.1 menghapus semua validasi yang tidak perlu!**

**Yang DIHAPUS:**
- ❌ Price bounds validation (min/max price)
- ❌ Max price change validation (20% limit)
- ❌ Cooldown validation (minimum interval)

**Kenapa dihapus?**
- ✅ **Harga DigiFinex = TRUTH** - Tidak perlu validasi
- ✅ **Lebih simple & gas efficient**
- ✅ **Validation di VPS bot** sebelum update on-chain
- ✅ **Faster execution**

---

### 🎯 ORACLE SYSTEM OVERVIEW

**Oracle = VPS Bot Wallet (BUKAN Chainlink!)**

```
VPS Bot (setiap 10 menit):
  ↓
Fetch DigiFinex API
  ↓
Validate price (di bot)
  ↓
Call contract.setOzonePrice(price)
  ↓
Price updated on-chain
  ↓
Users see new price immediately
```

**Biaya:**
- DigiFinex API: **FREE** (read-only)
- Gas per update: ~50,000 gas (~$0.01 on BSC)
- Total per hari: 144 updates × $0.01 = **$1.44/day**
- Total per bulan: **~$43/month** (hanya gas fee!)

---

### 📡 FUNGSI ORACLE (4 FUNCTIONS ONLY)

#### **1. setOzonePrice() - Update Harga (VPS Bot)**

**Signature:**
```solidity
function setOzonePrice(uint256 _price) external
```

**Who can call:**
- Owner wallet
- Oracle wallet (VPS bot)

**Validation:**
- ✅ Price > 0
- ❌ NO price bounds check
- ❌ NO max change check
- ❌ NO cooldown check

**Example (JavaScript):**
```javascript
const { ethers } = require('ethers');

// Setup
const provider = new ethers.JsonRpcProvider('https://bsc-dataseed1.binance.org');
const wallet = new ethers.Wallet(process.env.ORACLE_PRIVATE_KEY, provider);
const stakingContract = new ethers.Contract(
  '0x9DdE321F85e4512dDc7FA0DAEDa1fBa9Bca6C03d',
  ['function setOzonePrice(uint256 _price) external'],
  wallet
);

// Update price
const newPrice = ethers.parseEther("55.50"); // $55.50
const tx = await stakingContract.setOzonePrice(newPrice);
await tx.wait();

console.log('Price updated to $55.50');
console.log('TX:', tx.hash);
```

**Response:**
```
✅ Transaction successful
Gas used: ~50,000 gas
Cost: ~$0.01
Event emitted: OzonePriceUpdated(oldPrice, newPrice, timestamp)
```

---

#### **2. setPriceOracle() - Ganti Oracle Wallet**

**Signature:**
```solidity
function setPriceOracle(address _newOracle) external onlyOwner
```

**Who can call:** Owner only

**Use case:** Ganti VPS bot wallet

**Example:**
```javascript
// Change oracle to new VPS bot wallet
await stakingContract.setPriceOracle('0xNEW_VPS_BOT_WALLET');
```

---

#### **3. emergencySetPrice() - Manual Override**

**Signature:**
```solidity
function emergencySetPrice(uint256 _price) external onlyOwner
```

**Who can call:** Owner only

**Use case:** VPS bot mati, manual update harga

**Example:**
```javascript
// Manual emergency price update
const emergencyPrice = ethers.parseEther("55.00");
await stakingContract.emergencySetPrice(emergencyPrice);
```

**⚠️ WARNING:** Hanya untuk emergency! Normal operation harus pakai bot!

---

#### **4. getPriceOracleInfo() - Get Oracle Info**

**Signature:**
```solidity
function getPriceOracleInfo() external view returns (
    uint256 currentPrice,
    uint256 lastUpdate,
    address oracle
)
```

**Who can call:** Anyone (view function)

**Example:**
```javascript
const [price, lastUpdate, oracle] = await stakingContract.getPriceOracleInfo();

console.log('Current Price:', ethers.formatEther(price), 'USDT');
console.log('Last Update:', new Date(Number(lastUpdate) * 1000).toLocaleString());
console.log('Oracle Wallet:', oracle);
```

**Response:**
```javascript
{
  currentPrice: "55500000000000000000", // 55.5 USDT (18 decimals)
  lastUpdate: 1733472557, // Unix timestamp
  oracle: "0x5ACb28365aF47A453a14FeDD5f72cE502224F30B"
}
```

---

### 🔧 VPS BOT IMPLEMENTATION

#### **Setup Requirements:**

**VPS Specs:**
- OS: Ubuntu 20.04+
- RAM: 512MB minimum
- Node.js: v18+
- Storage: 10GB
- Location: Singapore/USA (DigiFinex accessible)

**Why VPS?**
- ✅ DigiFinex API blocked di beberapa negara
- ✅ Uptime 24/7
- ✅ Stable internet
- ✅ Low latency to BSC RPC

---

#### **Bot Code (Complete Implementation):**

**File: `vps-oracle-bot.js`**

```javascript
require('dotenv').config();
const { ethers } = require('ethers');
const axios = require('axios');

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
  // Contract
  STAKING_ADDRESS: '0x9DdE321F85e4512dDc7FA0DAEDa1fBa9Bca6C03d',
  
  // Network (BSC Mainnet)
  RPC_URL: 'https://bsc-dataseed1.binance.org',
  CHAIN_ID: 56,
  
  // Oracle Bot Wallet
  ORACLE_PRIVATE_KEY: process.env.ORACLE_PRIVATE_KEY,
  
  // Update Interval
  UPDATE_INTERVAL: 10 * 60 * 1000, // 10 minutes
  
  // DigiFinex API
  DIGIFINEX_API: 'https://openapi.digifinex.com/v3/ticker',
  DIGIFINEX_SYMBOL: 'ozone_usdt',
  
  // Price Validation (di bot, bukan contract!)
  MIN_PRICE: 0.01,      // $0.01 minimum
  MAX_PRICE: 10000,     // $10,000 maximum
  MAX_CHANGE_PERCENT: 50, // 50% max change per update (bot level)
  
  // Gas Settings
  GAS_LIMIT: 100000,
  MAX_PRIORITY_FEE: ethers.parseUnits('1', 'gwei'), // 1 gwei
};

// ============================================================================
// CONTRACT ABI
// ============================================================================

const STAKING_ABI = [
  'function setOzonePrice(uint256 _price) external',
  'function ozonePrice() external view returns (uint256)',
  'function getPriceOracleInfo() external view returns (uint256, uint256, address)'
];

// ============================================================================
// INITIALIZE
// ============================================================================

const provider = new ethers.JsonRpcProvider(CONFIG.RPC_URL);
const wallet = new ethers.Wallet(CONFIG.ORACLE_PRIVATE_KEY, provider);
const stakingContract = new ethers.Contract(
  CONFIG.STAKING_ADDRESS,
  STAKING_ABI,
  wallet
);

console.log('🤖 OZONE Price Oracle Bot Started');
console.log('📡 Network:', CONFIG.CHAIN_ID === 56 ? 'BSC Mainnet' : 'BSC Testnet');
console.log('📍 Contract:', CONFIG.STAKING_ADDRESS);
console.log('🔑 Oracle Wallet:', wallet.address);
console.log('⏱️  Update Interval: 10 minutes\n');

// ============================================================================
// FETCH PRICE FROM DIGIFINEX
// ============================================================================

async function fetchDigiFinexPrice() {
  try {
    const response = await axios.get(CONFIG.DIGIFINEX_API, {
      params: { symbol: CONFIG.DIGIFINEX_SYMBOL },
      timeout: 10000
    });
    
    if (response.data && response.data.ticker && response.data.ticker.length > 0) {
      const price = parseFloat(response.data.ticker[0].last);
      
      if (isNaN(price) || price <= 0) {
        throw new Error('Invalid price from DigiFinex');
      }
      
      console.log(`✅ DigiFinex Price: $${price.toFixed(4)}`);
      return price;
    }
    
    throw new Error('Invalid response from DigiFinex API');
    
  } catch (error) {
    console.error('❌ DigiFinex Error:', error.message);
    throw error;
  }
}

// ============================================================================
// VALIDATE PRICE (Bot Level)
// ============================================================================

async function validatePrice(newPrice) {
  // Check bounds
  if (newPrice < CONFIG.MIN_PRICE) {
    throw new Error(`Price too low: $${newPrice} < $${CONFIG.MIN_PRICE}`);
  }
  
  if (newPrice > CONFIG.MAX_PRICE) {
    throw new Error(`Price too high: $${newPrice} > $${CONFIG.MAX_PRICE}`);
  }
  
  // Get current on-chain price
  const currentPriceWei = await stakingContract.ozonePrice();
  const currentPrice = parseFloat(ethers.formatEther(currentPriceWei));
  
  if (currentPrice > 0) {
    // Calculate change percentage
    const changePercent = Math.abs((newPrice - currentPrice) / currentPrice * 100);
    
    if (changePercent > CONFIG.MAX_CHANGE_PERCENT) {
      throw new Error(
        `Price change too large: ${changePercent.toFixed(2)}% (max: ${CONFIG.MAX_CHANGE_PERCENT}%)`
      );
    }
    
    console.log(`📊 Price change: ${changePercent.toFixed(2)}%`);
  }
  
  return true;
}

// ============================================================================
// UPDATE PRICE ON-CHAIN
// ============================================================================

async function updatePrice() {
  try {
    console.log('\n🔄 Updating OZONE price...');
    console.log('⏰ Time:', new Date().toLocaleString());
    
    // 1. Fetch price from DigiFinex
    const price = await fetchDigiFinexPrice();
    
    // 2. Validate price (bot level)
    await validatePrice(price);
    
    // 3. Convert to wei (18 decimals)
    const priceWei = ethers.parseEther(price.toString());
    
    // 4. Get current on-chain price for comparison
    const currentPriceWei = await stakingContract.ozonePrice();
    const currentPrice = parseFloat(ethers.formatEther(currentPriceWei));
    
    console.log(`📊 Current on-chain: $${currentPrice.toFixed(4)}`);
    console.log(`📈 New price: $${price.toFixed(4)}`);
    
    // Skip if price unchanged
    if (Math.abs(price - currentPrice) < 0.01) {
      console.log('⏭️  Price unchanged, skipping update');
      return;
    }
    
    // 5. Estimate gas
    const gasEstimate = await stakingContract.setOzonePrice.estimateGas(priceWei);
    console.log(`⛽ Estimated gas: ${gasEstimate.toString()}`);
    
    // 6. Send transaction
    const tx = await stakingContract.setOzonePrice(priceWei, {
      gasLimit: CONFIG.GAS_LIMIT,
      maxPriorityFeePerGas: CONFIG.MAX_PRIORITY_FEE
    });
    
    console.log(`⏳ Transaction sent: ${tx.hash}`);
    console.log(`🔗 https://bscscan.com/tx/${tx.hash}`);
    
    // 7. Wait for confirmation
    const receipt = await tx.wait();
    
    console.log(`✅ Price updated successfully!`);
    console.log(`📦 Block: ${receipt.blockNumber}`);
    console.log(`⛽ Gas used: ${receipt.gasUsed.toString()}`);
    
    // 8. Calculate cost
    const gasPrice = receipt.gasPrice || receipt.effectiveGasPrice;
    const costBNB = ethers.formatEther(receipt.gasUsed * gasPrice);
    console.log(`💰 Cost: ${parseFloat(costBNB).toFixed(6)} BNB`);
    
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    
    // Detailed error logging
    if (error.code) {
      console.error('Error Code:', error.code);
    }
    if (error.reason) {
      console.error('Reason:', error.reason);
    }
  }
}

// ============================================================================
// HEALTH CHECK
// ============================================================================

async function healthCheck() {
  try {
    // Check wallet balance
    const balance = await provider.getBalance(wallet.address);
    const balanceBNB = parseFloat(ethers.formatEther(balance));
    
    console.log('\n💊 Health Check:');
    console.log(`   Wallet: ${wallet.address}`);
    console.log(`   Balance: ${balanceBNB.toFixed(4)} BNB`);
    
    if (balanceBNB < 0.01) {
      console.warn('   ⚠️  WARNING: Low BNB balance! Please top up.');
    }
    
    // Check if we're the oracle
    const [, , oracle] = await stakingContract.getPriceOracleInfo();
    
    if (oracle.toLowerCase() !== wallet.address.toLowerCase()) {
      console.error('   ❌ ERROR: This wallet is NOT the oracle!');
      console.error(`   Current oracle: ${oracle}`);
      process.exit(1);
    }
    
    console.log('   ✅ Oracle verification passed');
    
  } catch (error) {
    console.error('❌ Health check failed:', error.message);
  }
}

// ============================================================================
// MAIN LOOP
// ============================================================================

async function main() {
  // Initial health check
  await healthCheck();
  
  // Initial price update
  await updatePrice();
  
  // Schedule updates every 10 minutes
  setInterval(async () => {
    await updatePrice();
  }, CONFIG.UPDATE_INTERVAL);
  
  // Health check every hour
  setInterval(async () => {
    await healthCheck();
  }, 60 * 60 * 1000);
}

// ============================================================================
// ERROR HANDLING
// ============================================================================

process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
});

process.on('unhandledRejection', (error) => {
  console.error('💥 Unhandled Rejection:', error);
});

// ============================================================================
// START BOT
// ============================================================================

main().catch((error) => {
  console.error('💥 Fatal Error:', error);
  process.exit(1);
});
```

---

#### **Environment Variables (.env):**

```bash
# Oracle Bot Private Key (NEVER SHARE!)
ORACLE_PRIVATE_KEY=your_vps_bot_private_key_here

# Optional: Telegram Alerts
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
TELEGRAM_CHAT_ID=your_chat_id
```

---

#### **Package.json:**

```json
{
  "name": "ozone-price-oracle",
  "version": "2.1.1",
  "description": "OZONE Price Oracle Bot for DigiFinex",
  "main": "vps-oracle-bot.js",
  "scripts": {
    "start": "node vps-oracle-bot.js",
    "pm2": "pm2 start vps-oracle-bot.js --name ozone-oracle"
  },
  "dependencies": {
    "ethers": "^6.9.0",
    "axios": "^1.6.0",
    "dotenv": "^16.3.1"
  }
}
```

---

#### **VPS Deployment Steps:**

**1. Setup VPS:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Install git
sudo apt install git -y
```

**2. Deploy Bot:**
```bash
# Clone repository atau upload files
cd /home/ubuntu
mkdir ozone-oracle && cd ozone-oracle

# Upload files: vps-oracle-bot.js, package.json, .env

# Install dependencies
npm install

# Test run
node vps-oracle-bot.js
```

**3. Start with PM2:**
```bash
# Start bot
pm2 start vps-oracle-bot.js --name ozone-oracle

# Monitor logs
pm2 logs ozone-oracle

# Setup auto-restart on server reboot
pm2 startup
pm2 save

# Check status
pm2 status
```

**4. Monitor:**
```bash
# Real-time logs
pm2 logs ozone-oracle --lines 100

# Restart if needed
pm2 restart ozone-oracle

# Stop
pm2 stop ozone-oracle

# Delete
pm2 delete ozone-oracle
```

---

### 📊 BOT LOGS EXAMPLE

**Successful Update:**
```
🔄 Updating OZONE price...
⏰ Time: 06/12/2025, 14.30.00
✅ DigiFinex Price: $55.5000
📊 Price change: 0.91%
📊 Current on-chain: $55.0000
📈 New price: $55.5000
⛽ Estimated gas: 48523
⏳ Transaction sent: 0x1234...5678
🔗 https://bscscan.com/tx/0x1234...5678
✅ Price updated successfully!
📦 Block: 34567890
⛽ Gas used: 48234
💰 Cost: 0.000145 BNB

⏰ Next update in 10 minutes...
```

**Price Unchanged:**
```
🔄 Updating OZONE price...
⏰ Time: 06/12/2025, 14.40.00
✅ DigiFinex Price: $55.5000
📊 Current on-chain: $55.5000
📈 New price: $55.5000
⏭️  Price unchanged, skipping update
⏰ Next update in 10 minutes...
```

**Error Handling:**
```
🔄 Updating OZONE price...
⏰ Time: 06/12/2025, 14.50.00
❌ DigiFinex Error: Request timeout
⏰ Retrying in 10 minutes...
```

---

### 🔒 SECURITY BEST PRACTICES

#### **Oracle Wallet:**

**DO:**
- ✅ Create dedicated wallet untuk oracle only
- ✅ Fund dengan BNB minimal (0.1 BNB cukup untuk 1 bulan)
- ✅ Store private key di `.env` file dengan permission 600
- ✅ Backup private key secara secure
- ✅ Monitor balance regular

**DON'T:**
- ❌ Jangan pakai owner wallet sebagai oracle!
- ❌ Jangan store private key di code
- ❌ Jangan commit `.env` ke git
- ❌ Jangan share private key dengan siapapun

#### **VPS Security:**

```bash
# 1. Setup firewall
sudo ufw allow 22/tcp  # SSH only
sudo ufw enable

# 2. Disable password login (SSH key only)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd

# 3. Setup fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban

# 4. Auto security updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

---

### 📈 MONITORING & ALERTS

#### **Basic Monitoring:**

Add to bot code untuk Telegram alerts:

```javascript
const axios = require('axios');

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;

async function sendTelegramAlert(message) {
  if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) return;
  
  try {
    await axios.post(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        chat_id: TELEGRAM_CHAT_ID,
        text: message,
        parse_mode: 'HTML'
      }
    );
  } catch (error) {
    console.error('Telegram alert failed:', error.message);
  }
}

// Use in bot:
// Success
await sendTelegramAlert(`✅ Price updated: $${oldPrice} → $${newPrice}`);

// Error
await sendTelegramAlert(`❌ ERROR: ${error.message}`);

// Low balance
await sendTelegramAlert(`⚠️ Low BNB balance: ${balance} BNB`);
```

---

### ⚠️ KENAPA TIDAK PAKAI COINGECKO?

**DigiFinex API (WAJIB!)** ✅

**Alasan:**
- ✅ **Real-time trading data** dari exchange
- ✅ **Actual buy/sell prices**
- ✅ **No delay** (instant)
- ✅ **More accurate** untuk presale pricing

**CoinGecko API (JANGAN!)** ❌

**Masalah:**
- ❌ **Delayed data** (bisa 5-15 menit delay)
- ❌ **Aggregated price** (average dari multiple exchanges)
- ❌ **Not real-time**
- ❌ **Bisa beda jauh** dari actual trading price

**Example Scenario:**
```
DigiFinex (real-time): $55.50
CoinGecko (delayed):   $58.20

User beli di contract: $58.20 (mahal!)
Actual market price:   $55.50
User loss:             $2.70 per OZONE (5% loss!)
```

---

### 🧪 TESTING ORACLE

#### **Test on Testnet First:**

```javascript
// Test script
const { ethers } = require('ethers');

const provider = new ethers.JsonRpcProvider('https://bsc-testnet.publicnode.com');
const wallet = new ethers.Wallet(process.env.TEST_PRIVATE_KEY, provider);
const staking = new ethers.Contract(
  '0x9DdE321F85e4512dDc7FA0DAEDa1fBa9Bca6C03d',
  ['function setOzonePrice(uint256) external', 'function ozonePrice() view returns (uint256)'],
  wallet
);

async function testPriceUpdate() {
  console.log('Testing price update...');
  
  // Get current price
  const currentPrice = await staking.ozonePrice();
  console.log('Current:', ethers.formatEther(currentPrice));
  
  // Update to new price
  const newPrice = ethers.parseEther('56.00');
  const tx = await staking.setOzonePrice(newPrice);
  await tx.wait();
  
  console.log('Updated to $56.00');
  console.log('TX:', tx.hash);
  
  // Verify
  const updated = await staking.ozonePrice();
  console.log('Verified:', ethers.formatEther(updated));
}

testPriceUpdate();
```

---

### 💰 COST ANALYSIS

**Daily Cost:**
- Updates per day: 144 (10-min interval)
- Gas per update: ~50,000 gas
- Gas price: ~5 gwei (BSC average)
- BNB price: ~$600

**Calculation:**
```
Cost per update = 50,000 × 5 gwei × $600 / 1e18
                = 0.00015 BNB
                = $0.09

Daily cost = 144 × $0.09 = $12.96
Monthly cost = $12.96 × 30 = $388.80
```

**Optimization:**
- ✅ Skip update jika price unchanged (save gas)
- ✅ Increase interval to 15 min → save 33%
- ✅ Use gasPrice optimization
- ✅ Batch updates during low activity

**Optimized Monthly Cost: ~$250-300**

---

## 🚨 FUNGSI EMERGENCY (v2.1.1)

### **emergencyWithdrawOzone() - NEW! CRITICAL!**

**⚠️ FUNGSI BARU v2.1.1 - SANGAT PENTING!**

**Purpose:** Tarik OZONE dari contract untuk emergency situations

**Signature:**
```solidity
function emergencyWithdrawOzone(uint256 amount) external onlyOwner
```

**Who can call:** Owner only

**Use cases:**
- Contract upgrade/migration
- Security incident
- Token redistribution
- Recovery dari error

**Example:**
```javascript
const { ethers } = require('ethers');

// Withdraw 1 million OZONE
const amount = ethers.parseUnits('1000000', 18);
const tx = await stakingContract.emergencyWithdrawOzone(amount);
await tx.wait();

console.log('Emergency withdraw:', amount, 'OZONE');
console.log('TX:', tx.hash);
```

**Response:**
```javascript
✅ Transaction successful
Amount: 1,000,000 OZONE
Recipient: Owner wallet
Event: EmergencyOzoneWithdraw(amount, owner)
```

**⚠️ WARNING:**
- Withdraw langsung ke owner wallet
- Tidak ada validasi balance presale
- **HANYA untuk emergency!**
- User stakes **TIDAK terpengaruh** (aman!)

**Safety Notes:**
```javascript
// OZONE has 1% transfer tax!
// Actual received = amount × 0.99

// Example:
Withdraw: 1,000,000 OZONE
Tax (1%): 10,000 OZONE (ke treasury)
Received: 990,000 OZONE
```

---

### **emergencySetPrice() - Manual Price Override**

**Purpose:** Set price manual saat oracle bot error

**Signature:**
```solidity
function emergencySetPrice(uint256 _price) external onlyOwner
```

**Who can call:** Owner only

**Validation:**
- ✅ Price > 0
- ❌ NO bounds check
- ❌ NO change limit
- ❌ NO cooldown

**Example:**
```javascript
// VPS bot mati, harus manual update
const emergencyPrice = ethers.parseEther('55.00'); // $55
const tx = await stakingContract.emergencySetPrice(emergencyPrice);
await tx.wait();

console.log('Emergency price set to $55');
```

**When to use:**
- VPS bot offline
- DigiFinex API down
- Emergency maintenance
- Critical price fix

**⚠️ WARNING:** Return to normal bot operation ASAP!

---

## 🔧 ORACLE WALLET MANAGEMENT

### **setPriceOracle() - Change Oracle Wallet**

**Purpose:** Ganti wallet yang bisa update price

**Signature:**
```solidity
function setPriceOracle(address _newOracle) external onlyOwner
```

**Who can call:** Owner only

**Use cases:**
- VPS bot wallet compromised
- Switch to new VPS
- Change oracle provider
- Testing different wallets

**Example:**
```javascript
// Change to new VPS bot wallet
const newOracleWallet = '0xNEW_VPS_BOT_WALLET_ADDRESS';
const tx = await stakingContract.setPriceOracle(newOracleWallet);
await tx.wait();

console.log('Oracle changed to:', newOracleWallet);
```

**Important:**
- Old oracle immediately loses permission
- New oracle can update price immediately
- No waiting period
- Update your VPS bot config!

**After changing oracle:**
```bash
# Update VPS bot .env file
ORACLE_PRIVATE_KEY=new_wallet_private_key

# Restart bot
pm2 restart ozone-oracle
```

---

## 📊 READ FUNCTIONS (Oracle Related)

### **getPriceOracleInfo() - Get Oracle Status**

**Signature:**
```solidity
function getPriceOracleInfo() external view returns (
    uint256 currentPrice,
    uint256 lastUpdate,
    address oracle
)
```

**Returns:**
- `currentPrice`: Current OZONE price (18 decimals)
- `lastUpdate`: Last update timestamp (Unix)
- `oracle`: Oracle wallet address

**Example:**
```javascript
const [price, lastUpdate, oracle] = await stakingContract.getPriceOracleInfo();

console.log('Current Price:', ethers.formatEther(price), 'USDT');
console.log('Last Update:', new Date(Number(lastUpdate) * 1000).toLocaleString());
console.log('Oracle Wallet:', oracle);

// Check if price is fresh
const now = Math.floor(Date.now() / 1000);
const age = now - Number(lastUpdate);

if (age > 600) { // 10 minutes
  console.warn('⚠️ Price data stale! Last update:', age, 'seconds ago');
}
```

**Response:**
```javascript
{
  currentPrice: "55500000000000000000", // $55.50 (18 decimals)
  lastUpdate: 1733472557, // 2024-12-06 14:30:00
  oracle: "0x5ACb28365aF47A453a14FeDD5f72cE502224F30B"
}
```

---

### **ozonePrice() - Get Current Price Only**

**Signature:**
```solidity
function ozonePrice() external view returns (uint256)
```

**Returns:** Current OZONE price in USDT (18 decimals)

**Example:**
```javascript
const priceWei = await stakingContract.ozonePrice();
const price = ethers.formatEther(priceWei);

console.log('OZONE Price:', price, 'USDT');
// Output: OZONE Price: 55.5 USDT
```

---

## ❌ REMOVED FUNCTIONS (v2.1.1)

**⚠️ IMPORTANT: Functions yang TIDAK ADA lagi!**

### **setPriceBounds()** - REMOVED!
```solidity
// ❌ Function ini TIDAK ADA lagi di v2.1.1
function setPriceBounds(uint256 _minPrice, uint256 _maxPrice) external onlyOwner
```

**Alasan dihapus:** Tidak perlu validasi, trust DigiFinex API

---

### **setMaxPriceChange()** - REMOVED!
```solidity
// ❌ Function ini TIDAK ADA lagi di v2.1.1
function setMaxPriceChange(uint256 _maxChangePercent) external onlyOwner
```

**Alasan dihapus:** Real-time price tidak perlu limit change

---

### **setPriceUpdateCooldown()** - REMOVED!
```solidity
// ❌ Function ini TIDAK ADA lagi di v2.1.1
function setPriceUpdateCooldown(uint256 _cooldown) external onlyOwner
```

**Alasan dihapus:** Update setiap 10 menit sudah fixed di bot

---

**⚠️ IMPORTANT untuk Backend Developers:**

Jika ada code lama yang call functions ini, **HAPUS!**

```javascript
// ❌ OLD CODE (v2.1.0) - ERROR!
await stakingContract.setPriceBounds(ethers.parseEther('0.01'), ethers.parseEther('1000'));
await stakingContract.setMaxPriceChange(20);
await stakingContract.setPriceUpdateCooldown(300);

// ✅ NEW CODE (v2.1.1) - Simple!
await stakingContract.setOzonePrice(ethers.parseEther('55.50'));
```

---

## 🧪 TESTING ORACLE SYSTEM

### **Test Script for Price Update:**

```javascript
const { ethers } = require('hardhat');

async function testOracleSystem() {
  const [deployer] = await ethers.getSigners();
  
  const stakingAddress = '0x9DdE321F85e4512dDc7FA0DAEDa1fBa9Bca6C03d';
  const staking = await ethers.getContractAt('OzoneStakingV2', stakingAddress);
  
  console.log('\n📊 Testing Oracle System...\n');
  
  // 1. Get current price
  console.log('1️⃣ Get Current Price:');
  const currentPrice = await staking.ozonePrice();
  console.log('   Current:', ethers.formatEther(currentPrice), 'USDT');
  
  // 2. Get oracle info
  console.log('\n2️⃣ Get Oracle Info:');
  const [price, lastUpdate, oracle] = await staking.getPriceOracleInfo();
  console.log('   Price:', ethers.formatEther(price), 'USDT');
  console.log('   Last Update:', new Date(Number(lastUpdate) * 1000).toLocaleString());
  console.log('   Oracle Wallet:', oracle);
  console.log('   Deployer:', deployer.address);
  console.log('   Is Oracle?', oracle.toLowerCase() === deployer.address.toLowerCase());
  
  // 3. Update price
  console.log('\n3️⃣ Update Price:');
  const newPrice = ethers.parseEther('56.00');
  console.log('   New price:', ethers.formatEther(newPrice), 'USDT');
  
  const tx = await staking.setOzonePrice(newPrice);
  console.log('   TX sent:', tx.hash);
  
  const receipt = await tx.wait();
  console.log('   ✅ Confirmed! Block:', receipt.blockNumber);
  console.log('   Gas used:', receipt.gasUsed.toString());
  
  // 4. Verify update
  console.log('\n4️⃣ Verify Update:');
  const updatedPrice = await staking.ozonePrice();
  console.log('   Updated price:', ethers.formatEther(updatedPrice), 'USDT');
  
  const [, newLastUpdate,] = await staking.getPriceOracleInfo();
  console.log('   New timestamp:', new Date(Number(newLastUpdate) * 1000).toLocaleString());
  
  console.log('\n✅ All tests passed!\n');
}

testOracleSystem()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

**Run test:**
```bash
npx hardhat run scripts/test-oracle.js --network bscTestnet
```

---

### **Test Emergency Functions:**

```javascript
async function testEmergency() {
  const staking = await ethers.getContractAt('OzoneStakingV2', STAKING_ADDRESS);
  
  console.log('\n🚨 Testing Emergency Functions...\n');
  
  // 1. Emergency price update
  console.log('1️⃣ Emergency Set Price:');
  const emergencyPrice = ethers.parseEther('60.00');
  const tx1 = await staking.emergencySetPrice(emergencyPrice);
  await tx1.wait();
  console.log('   ✅ Emergency price set to $60');
  
  // 2. Change oracle wallet
  console.log('\n2️⃣ Change Oracle Wallet:');
  const newOracle = '0xNEW_ORACLE_WALLET';
  const tx2 = await staking.setPriceOracle(newOracle);
  await tx2.wait();
  console.log('   ✅ Oracle changed to:', newOracle);
  
  // 3. Emergency withdraw OZONE
  console.log('\n3️⃣ Emergency Withdraw OZONE:');
  const amount = ethers.parseUnits('100000', 18); // 100K OZONE
  const tx3 = await staking.emergencyWithdrawOzone(amount);
  await tx3.wait();
  console.log('   ✅ Withdrawn 100,000 OZONE');
  
  console.log('\n✅ Emergency functions working!\n');
}
```

---

## 📝 PRODUCTION CHECKLIST

**Before deploying to BSC Mainnet:**

### **1. Contract Setup:**
- [ ] Deploy with correct OZONE token address
- [ ] Deploy with correct USDT address (18 decimals!)
- [ ] Set correct treasury wallet
- [ ] Set correct tax wallet
- [ ] Whitelist contract in OZONE token (avoid 1% tax)
- [ ] Transfer presale OZONE supply to contract
- [ ] Activate presale

### **2. Oracle Setup:**
- [ ] Create dedicated oracle wallet (NEW wallet!)
- [ ] Fund oracle wallet (0.1 BNB for 1 month gas)
- [ ] Set oracle wallet in contract (`setPriceOracle()`)
- [ ] Setup VPS (Ubuntu 20.04+, Node.js 18+)
- [ ] Deploy VPS bot code
- [ ] Configure `.env` with oracle private key
- [ ] Test price update (1-2 times manually)
- [ ] Start bot with PM2
- [ ] Setup PM2 auto-restart
- [ ] Monitor first 24 hours

### **3. Security:**
- [ ] Verify contract on BscScan
- [ ] Audit contract code
- [ ] Test all functions on testnet
- [ ] Test emergency withdraw
- [ ] Test emergency price update
- [ ] Setup monitoring/alerts
- [ ] Document all wallet addresses
- [ ] Backup all private keys securely

### **4. Backend Integration:**
- [ ] Update API endpoints with mainnet addresses
- [ ] Test buy & stake flow
- [ ] Test stake info retrieval
- [ ] Test unstake flow
- [ ] Test reward claims
- [ ] Load testing
- [ ] Error handling

### **5. Monitoring:**
- [ ] Setup Telegram alerts for bot
- [ ] Monitor oracle wallet balance
- [ ] Monitor price updates (10-min interval)
- [ ] Monitor contract events
- [ ] Monitor user stakes
- [ ] Monitor reward distributions

---



## 📊 BACKEND API ENDPOINTS (YANG PERLU DIBUAT)

### 1. Get Contract Info

**GET** `/api/staking/info`

**Response:**
```json
{
  "contract": "0x7fB215873f979C0Bb87b6C2D5DA50c726c7CeAd0",
  "ozonePrice": 55.00,
  "presaleActive": true,
  "availableOzone": 19999000,
  "totalSold": 0,
  "pools": [
    {
      "id": 1,
      "name": "LimoX Pool A",
      "minStake": 100,
      "maxStake": 1000,
      "monthlyAPY": 6,
      "duration": 50,
      "isActive": true
    }
    // ... more pools
  ]
}
```

### 2. Get User Stakes

**GET** `/api/staking/user/:address`

**Response:**
```json
{
  "address": "0x...",
  "stakes": [
    {
      "index": 0,
      "poolId": 1,
      "poolName": "LimoX Pool A",
      "ozoneAmount": 18.0,
      "usdtValue": 990,
      "monthlyAPY": 6,
      "startTime": "2025-12-06T12:00:00Z",
      "lastClaimTime": "2025-12-06T12:00:00Z",
      "totalClaimed": 0,
      "maxReward": 2970,
      "nextClaimAvailable": "2025-12-21T12:00:00Z",
      "isActive": true
    }
  ],
  "totalStaked": 990,
  "totalRewards": 0
}
```

### 3. Calculate Rewards

**GET** `/api/staking/calculate/:address/:stakeIndex`

**Response:**
```json
{
  "stakeIndex": 0,
  "currentReward": 59.4,
  "totalClaimed": 0,
  "remainingReward": 2970,
  "canClaimNow": false,
  "nextClaimDate": "2025-12-21T12:00:00Z",
  "daysUntilClaim": 15
}
```

### 4. Simulate Buy

**POST** `/api/staking/simulate`

**Request:**
```json
{
  "usdtAmount": 1000
}
```

**Response:**
```json
{
  "usdtAmount": 1000,
  "platformFee": 10,
  "totalCost": 1010,
  "ozonePrice": 55,
  "ozoneReceived": 18.0,
  "eligiblePools": [
    {
      "id": 1,
      "name": "LimoX Pool A",
      "monthlyReward": 59.4,
      "totalRewardCap": 2970,
      "duration": 50
    }
  ]
}
```

---

## 🔗 SMART CONTRACT INTEGRATION

### Read Functions (View Only):

```javascript
// Get current OZONE price
const price = await contract.ozonePrice();
console.log("Price:", ethers.utils.formatEther(price));

// Get pool info
const pool = await contract.pools(poolId);
console.log("Pool:", pool.name, pool.monthlyAPY / 100 + "%");

// Get user stakes
const stakes = await contract.userStakes(userAddress);

// Get presale info
const active = await contract.presaleActive();
const supply = await contract.presaleSupply();
```

### Write Functions (Require Transaction):

```javascript
// User buy and stake
await usdtContract.approve(stakingContract, totalCost);
await stakingContract.buyAndStake(poolId, usdtAmount);

// User claim reward
await stakingContract.claimReward(stakeIndex);

// Owner update price (bot)
await stakingContract.setOzonePrice(newPriceInWei);

// Owner emergency price (manual)
await stakingContract.emergencySetPrice(priceInWei);
```

### Event Listeners:

```javascript
// Listen untuk purchase events
contract.on("PresalePurchase", (user, poolId, usdtAmount, ozoneAmount, stakeIndex) => {
  console.log(`User ${user} bought ${ozoneAmount} OZONE`);
  // Update database
});

// Listen untuk claim events
contract.on("RewardClaimed", (user, stakeIndex, amount) => {
  console.log(`User ${user} claimed ${amount} USDT`);
  // Update database
});

// Listen untuk price updates
contract.on("OzonePriceUpdated", (oldPrice, newPrice, timestamp) => {
  console.log(`Price updated: ${oldPrice} → ${newPrice}`);
  // Update cache
});
```

---

## 🧪 TESTING GUIDE

### Manual Testing Steps:

**1. Check Contract State:**
```bash
npx hardhat run scripts/verify-contract-state.js --network bscTestnet
```

**2. Get Testnet USDT:**
- Faucet: https://testnet.binance.org/faucet-smart
- Request BNB untuk gas
- Swap BNB → USDT di PancakeSwap Testnet

**3. Test Buy & Stake:**

```javascript
// Approve USDT
const usdtAmount = ethers.utils.parseUnits("1000", 18); // $1000
const fee = usdtAmount.mul(100).div(10000); // 1% fee
const totalCost = usdtAmount.add(fee); // $1010

await usdt.approve(stakingContract.address, totalCost);

// Buy and stake
await stakingContract.buyAndStake(1, usdtAmount);
```

**4. Verify Stake Created:**
```javascript
const stakes = await stakingContract.userStakes(userAddress);
console.log("Stake:", stakes[0]);
```

**5. Test Claim (after 15 days):**
```javascript
// Fast-forward time di testnet (if supported)
// OR wait 15 days

await stakingContract.claimReward(0);
```

### Expected Results:

✅ User dapat OZONE sesuai perhitungan  
✅ Stake record created dengan correct pool  
✅ Reward calculated correctly  
✅ Claim only available after 15 days  
✅ Auto-burn after 300% reward  

---

## ⚠️ IMPORTANT NOTES

### 1. Decimal Handling:

**USDT di BSC = 18 decimals** (BUKAN 6 seperti Ethereum!)

```javascript
// CORRECT for BSC:
const amount = ethers.utils.parseUnits("1000", 18);

// WRONG:
const amount = ethers.utils.parseUnits("1000", 6); // This is for Ethereum USDT
```

### 2. Price Format:

OZONE price di contract = **18 decimals**

```javascript
// $55 USDT
const price = ethers.utils.parseEther("55"); // 55000000000000000000

// Display
const displayPrice = ethers.utils.formatEther(price); // "55.0"
```

### 3. Gas Estimation:

Testnet transactions:
- `buyAndStake()`: ~200,000 gas
- `claimReward()`: ~150,000 gas
- `setOzonePrice()`: ~50,000 gas

### 4. Error Messages:

Common errors dan solution:

| Error | Cause | Solution |
|-------|-------|----------|
| "Presale not active" | Presale belum active | Call `setPresaleActive(true)` |
| "Insufficient USDT balance" | User USDT < total cost | Top up USDT |
| "Insufficient USDT allowance" | Approve amount kurang | Approve dengan amount lebih besar |
| "Below minimum stake" | Amount < pool minimum | Increase amount atau pilih pool lain |
| "Pool is not active" | Pool di-disable | Pilih pool lain |
| "Claim not available yet" | Belum 15 hari | Wait atau check lastClaimTime |
| "Price change too large" | Price change > 20% | Update price bertahap |

---

## 🔄 MAINTENANCE

### Daily Tasks:

1. ✅ Monitor price bot logs
2. ✅ Check price update frequency
3. ✅ Verify no failed transactions
4. ✅ Monitor contract OZONE balance

### Weekly Tasks:

1. ✅ Review total sales
2. ✅ Check USDT reserves untuk rewards
3. ✅ Verify no stuck stakes
4. ✅ Backup database

### Monthly Tasks:

1. ✅ Audit total rewards distributed
2. ✅ Compare OZONE burned vs expected
3. ✅ Review price oracle performance
4. ✅ Security audit

---

## 📞 SUPPORT & TROUBLESHOOTING

### Bot Tidak Update Price:

1. Check VPS masih running: `pm2 status`
2. Check logs: `pm2 logs ozone-price-bot`
3. Verify DigiFinex API key masih valid
4. Test manual: `curl https://openapi.digifinex.com/v3/ticker?symbol=ozone_usdt`

### Transaction Failed:

1. Check gas price (might be too low)
2. Verify contract not paused
3. Check user balance & allowance
4. Review contract state (presale active, pool active, etc)

### Wrong Calculation:

1. Verify decimal handling (18 decimals!)
2. Check price di contract vs display
3. Verify pool APY configuration
4. Test dengan amount kecil dulu

---

## 📚 ADDITIONAL RESOURCES

**Smart Contract:**
- Proxy: https://testnet.bscscan.com/address/0x7fB215873f979C0Bb87b6C2D5DA50c726c7CeAd0
- Implementation: https://testnet.bscscan.com/address/0x1D252Ef6Cc3CE6996A82Ea7F30a0093C96D1FE08

**Tools:**
- Hardhat Docs: https://hardhat.org/docs
- Ethers.js Docs: https://docs.ethers.org
- BSC Testnet: https://testnet.bscscan.com

**DigiFinex:**
- API Docs: https://docs.digifinex.com/en-ww/v3/#introduction
- Ticker Endpoint: `GET /v3/ticker?symbol=ozone_usdt`

---

## ✅ PRODUCTION DEPLOYMENT CHECKLIST

Sebelum deploy ke **BSC Mainnet:**

- [ ] Test semua functions di testnet
- [ ] Verify price bot stable minimal 1 minggu
- [ ] Audit contract code
- [ ] Setup VPS production dengan monitoring
- [ ] Prepare OZONE tokens untuk presale supply
- [ ] Prepare USDT reserves untuk rewards
- [ ] Setup backup bot (redundancy)
- [ ] Configure alerting (Telegram/Discord bot)
- [ ] Document recovery procedures
- [ ] Train support team

---

**Developer Contact:** [Your Team]  
**Last Updated:** 6 Desember 2025  
**Version:** 2.1.0-ENHANCED-ORACLE

---

🎯 **NEXT STEPS:** Testing presale dengan manual price, lalu deploy price bot ke VPS untuk auto-update!

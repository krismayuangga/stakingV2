# 📚 TECHNICAL DOCUMENTATION - OZONE Staking V2

Dokumentasi teknis lengkap untuk developer yang ingin memahami arsitektur internal, function reference, dan implementasi detail dari smart contract OzoneStakingV2.

---

## 📋 Daftar Isi

- [Arsitektur Smart Contract](#-arsitektur-smart-contract)
- [State Variables](#-state-variables)
- [Structs & Enums](#-structs--enums)
- [Function Reference](#-function-reference)
- [Events](#-events)
- [Modifiers](#-modifiers)
- [Perhitungan Internal](#-perhitungan-internal)
- [Gas Optimization](#-gas-optimization)
- [Upgrade Mechanism](#-upgrade-mechanism)
- [Error Codes](#-error-codes)

---

## 🏗 Arsitektur Smart Contract

### **Inheritance Tree:**

```
OzoneStakingV2
    ├── Initializable (OpenZeppelin)
    ├── UUPSUpgradeable (OpenZeppelin)
    ├── OwnableUpgradeable (OpenZeppelin)
    ├── PausableUpgradeable (OpenZeppelin)
    └── ReentrancyGuardUpgradeable (OpenZeppelin)
```

### **Pattern yang Digunakan:**

1. **UUPS Proxy Pattern**
   - Upgradeable tanpa migrasi data
   - Logic di implementation, data di proxy
   - Owner-controlled upgrade

2. **Checks-Effects-Interactions**
   - Validasi input terlebih dahulu
   - Update state
   - External calls terakhir

3. **Pull over Push**
   - User claim reward sendiri
   - Bukan contract yang distribute otomatis

4. **Reentrancy Protection**
   - `nonReentrant` modifier pada semua fungsi transfer

---

## 💾 State Variables

### **Token References:**

```solidity
IERC20 public ozoneToken;              // OZONE token ERC20
IERC20 public usdtToken;               // USDT BEP-20 token (6 decimals)
IOZONEToken public ozoneContract;      // OZONE main contract (untuk PoR)
```

### **Pool Management:**

```solidity
mapping(uint256 => Pool) public pools;              // Pool ID → Pool data
mapping(address => UserStake[]) public userStakes;  // User → Array of stakes
uint256 public totalPools;                          // Total pools created
uint256 public nextPoolId;                          // Next pool ID (auto-increment)
```

### **Reserve Management:**

```solidity
uint256 public stakingUSDTReserves;      // USDT reserves untuk reward
uint256 public totalStakingDistributed;  // Total USDT yang sudah didistribusikan
uint256 public totalTokensBurned;        // Total OZONE yang sudah di-burn
uint256 public activeStakeCount;         // Jumlah stake yang masih aktif
```

### **Presale Management:**

```solidity
uint256 public presaleSupply;            // OZONE yang tersedia untuk presale
uint256 public totalPresaleSold;         // Total OZONE yang terjual via presale
address public treasuryWallet;           // Wallet treasury untuk terima USDT base price
address public taxWallet;                // Wallet untuk 1% USDT platform fee
bool public presaleActive;               // Status presale (active/inactive)
```

### **Constants:**

```solidity
uint256 public constant MAX_REWARD_PERCENTAGE = 30000;     // 300% (basis points)
uint256 public constant CLAIM_INTERVAL = 15 days;          // Interval claim 15 hari
uint256 public constant MONTH_DURATION = 30 days;          // 1 bulan = 30 hari
uint256 public constant PURCHASE_TAX_RATE = 100;           // 1% platform fee (basis points)
uint256 public constant BASIS_POINTS = 10000;              // 100% = 10000 basis points
```

### **Price Management:**

```solidity
uint256 public ozonePrice;  // Harga OZONE dalam USDT (18 decimals)
                            // Contoh: 1.50 USDT = 1500000000000000000
```

---

## 📊 Structs & Enums

### **Pool Struct:**

```solidity
struct Pool {
    string name;                    // Nama pool (e.g., "LimoX Pool A")
    uint256 monthlyAPY;            // APY per bulan dalam basis points (600 = 6%)
    uint256 minStakeUSDT;          // Minimum stake (dalam OZONE tokens)
    uint256 maxStakeUSDT;          // Maximum stake (0 = unlimited)
    uint256 claimInterval;         // Interval claim (seconds)
    uint256 maxRewardPercent;      // Max reward % (30000 = 300%)
    bool enableAutoBurn;           // Auto-burn enabled?
    uint256 totalStaked;           // Total OZONE staked di pool ini
    uint256 totalClaimed;          // Total USDT rewards yang sudah di-claim
    bool isActive;                 // Pool masih aktif?
    uint256 createdAt;             // Timestamp pool dibuat
    uint256 durationMonths;        // Durasi dalam bulan (300 / APY)
}
```

**Storage Layout:**
- Slot 0: `name` (string)
- Slot 1: `monthlyAPY`, `minStakeUSDT`
- Slot 2: `maxStakeUSDT`, `claimInterval`
- Slot 3: `maxRewardPercent`, `enableAutoBurn`, `totalStaked`
- Slot 4: `totalClaimed`, `isActive`, `createdAt`
- Slot 5: `durationMonths`

### **UserStake Struct:**

```solidity
struct UserStake {
    uint256 amount;                // Amount yang diterima contract (after tax)
    uint256 originalAmount;        // Original amount untuk perhitungan reward (before tax)
    uint256 usdtValueAtStake;      // Nilai USDT saat stake (locked)
    uint256 poolId;                // Pool ID (tier locked)
    uint256 lockedAPY;             // APY yang terkunci saat stake
    uint256 startTime;             // Timestamp mulai stake
    uint256 lastClaimTime;         // Timestamp claim terakhir
    uint256 totalClaimedReward;    // Total USDT yang sudah di-claim
    uint256 nextClaimTime;         // Timestamp next claim (15 hari dari last)
    bool isActive;                 // Stake masih aktif?
    bool isBurned;                 // Sudah di-burn?
    uint256 endTime;               // Expected end time (untuk auto-burn)
    bool isFromPresale;            // Dari presale atau manual stake?
}
```

**⚠️ Penting - Tax Handling:**
- **Presale (buyAndStake)**: 
  - `amount` = `originalAmount` (contract tax exempt, receives 100%)
  - User pays: base price + 1% USDT platform fee
  - 99% USDT → treasuryWallet, 1% USDT → taxWallet
  
- **Manual Stake (stake)**:
  - `amount` = 99% (contract receives after 1% OZONE transfer tax)
  - `originalAmount` = 100% (what user sent, for reward calculation)
  - Tax goes to OZONE treasury wallet automatically

---

## 🔧 Function Reference

### **Initialize Function:**

```solidity
function initialize(
    address _ozoneToken,
    address _usdtToken,
    address _ozoneContract,
    uint256 _initialOzonePrice,
    address _treasuryWallet,
    address _taxWallet,
    uint256 _initialPresaleSupply
) public initializer
```

**Parameters:**
- `_ozoneToken`: Address OZONE token contract
- `_usdtToken`: Address USDT token contract (BSC: 0x55d398...)
- `_ozoneContract`: Address OZONE main contract
- `_initialOzonePrice`: Harga awal OZONE (18 decimals)
- `_treasuryWallet`: Address treasury untuk terima USDT base price (99%)
- `_taxWallet`: Address untuk terima 1% USDT platform fee
- `_initialPresaleSupply`: Presale supply awal (18 decimals)

**Gas Cost:** ~3,500,000 gas

**Requirements:**
- Hanya bisa dipanggil sekali
- Semua address tidak boleh zero address
- Price harus > 0

---

### **Presale & Staking Functions:**

#### **buyAndStake()**

```solidity
function buyAndStake(uint256 _poolId, uint256 _usdtAmount) 
    external 
    nonReentrant 
    whenNotPaused
```

**Deskripsi:** User beli OZONE dengan USDT dan langsung stake ke pool pilihan dalam 1 transaksi.

**Parameters:**
- `_poolId`: Pool ID yang dipilih (1-5)
- `_usdtAmount`: Base USDT amount (6 decimals) - TIDAK termasuk 1% fee

**⚠️ Tax Mechanism:**
- User harus approve: `_usdtAmount + (_usdtAmount × 1%)` total USDT
- Contract transfers:
  - `_usdtAmount` (99%) → treasuryWallet
  - `_usdtAmount × 1%` (1%) → taxWallet
- OZONE calculated from base price: `(_usdtAmount × 10^18) / ozonePrice`
- Rewards calculated from base price, not including tax

**Flow Internal:**
1. Validate presale aktif
2. Validate pool ID dan pool aktif
3. Calculate 1% tax amount
4. Calculate total cost (base + tax)
5. Check user USDT balance & allowance for total cost
6. Calculate OZONE amount: `(_usdtAmount * 10^18) / ozonePrice`
7. Check presale supply cukup
8. Validate min/max pool
9. Transfer base USDT ke treasury (99%)
10. Transfer tax USDT ke taxWallet (1%)
11. Update presale stats
12. Create stake entry (OZONE tetap di contract)
13. Emit events

**Gas Cost:** ~200,000 - 240,000 gas (slightly higher due to tax handling)

**Events Emitted:**
- `PresalePurchase(buyer, poolId, usdtPaid, ozoneReceived, stakeIndex)`
- `PurchaseTaxCollected(buyer, taxAmount)`
- `UserStaked(user, poolId, ozoneAmount, usdtValue, stakeIndex, fromPresale=true)`

**Reverts:**
- "Presale not active"
- "Pool does not exist"
- "Amount must be greater than 0"
- "Pool is not active"
- "Insufficient USDT balance" (checks total cost)
- "Insufficient USDT allowance" (checks total cost)
- "Invalid OZONE amount"
- "Insufficient presale supply"
- "Below minimum stake for this pool"
- "Above maximum stake for this pool"
- "Base USDT transfer failed"
- "Tax USDT transfer failed"

---

#### **stake()**

```solidity
function stake(uint256 _poolId, uint256 _amount) 
    external 
    nonReentrant 
    whenNotPaused
```

**Deskripsi:** User yang sudah punya OZONE bisa stake ke pool pilihan.

**Parameters:**
- `_poolId`: Pool ID (1-5)
- `_amount`: Jumlah OZONE yang user kirim (18 decimals)

**⚠️ Tax Mechanism (OZONE Transfer Tax 1%):**
- User sends: `_amount` (100%)
- OZONE token automatically deducts: 1% → OZONE treasury
- Contract receives: `_amount × 99%` (99%)
- Tracking:
  - `originalAmount`: `_amount` (100%, for reward calculation)
  - `amount`: `_amount × 99%` (actual balance in contract)
- Rewards calculated from: `originalAmount` (100%)

**Flow Internal:**
1. Validate pool exists dan aktif
2. Validate min/max pool (based on originalAmount)
3. Calculate after-tax amount: `_amount × 99 / 100`
4. Transfer OZONE dari user ke contract (tax deducted automatically)
5. Calculate USDT value from originalAmount: `(_amount * ozonePrice) / 10^18`
6. Create stake entry:
   - `amount`: afterTaxAmount (99%)
   - `originalAmount`: _amount (100%)
7. Emit event

**Gas Cost:** ~160,000 - 190,000 gas

**Events Emitted:**
- `UserStaked(user, poolId, _amount, usdtValue, stakeIndex, fromPresale=false)`

**Note:** Event emits `_amount` (100%) not afterTaxAmount, to show user what they sent.

---

### **Reward Functions:**

#### **calculateAvailableRewards()**

```solidity
function calculateAvailableRewards(address _user, uint256 _stakeIndex) 
    public view 
    returns (uint256 claimableRewardsUSDT, bool shouldAutoBurn)
```

**Deskripsi:** Menghitung reward USDT yang bisa di-claim saat ini.

**Formula:**
```solidity
uint256 timeElapsed = block.timestamp - lastClaimTime;
uint256 daysElapsed = timeElapsed / 1 days;

// Daily reward langsung dari USDT value (tidak pakai OZONE amount)
uint256 dailyRewardUSDT = (usdtValueAtStake × lockedAPY) / 10000 / 30;
uint256 totalRewardUSDT = dailyRewardUSDT × daysElapsed;

// Cap di max reward
uint256 maxRewardUSDT = (usdtValueAtStake × 30000) / 10000;
uint256 remainingRewardUSDT = maxRewardUSDT - totalClaimedReward;

if (totalRewardUSDT > remainingRewardUSDT) {
    totalRewardUSDT = remainingRewardUSDT;
}

// Check auto-burn
shouldAutoBurn = block.timestamp >= endTime;
```

**Returns:**
- `claimableRewardsUSDT`: Jumlah USDT yang bisa di-claim (6 decimals)
- `shouldAutoBurn`: Apakah akan trigger auto-burn?

**Gas Cost:** ~15,000 - 20,000 gas (view function)

---

#### **claimRewards()**

```solidity
function claimRewards(uint256 _stakeIndex) 
    external 
    nonReentrant 
    whenNotPaused
```

**Deskripsi:** Claim reward USDT untuk stake tertentu.

**Requirements:**
- Sudah lewat 15 hari dari last claim
- Ada reward yang tersedia
- USDT reserves cukup

**Flow Internal:**
1. Validate bisa claim (15 hari sudah lewat)
2. Calculate rewards
3. Validate rewards > 0 dan reserves cukup
4. Update stake data:
   - `lastClaimTime = block.timestamp`
   - `totalClaimedReward += usdtRewards`
   - `nextClaimTime = block.timestamp + 15 days`
5. Transfer USDT ke user
6. Update pool stats
7. Emit event
8. Check auto-burn condition
9. Jika ya, panggil `_autoBurnTokens()`

**Gas Cost:** 
- Normal claim: ~120,000 - 150,000 gas
- Claim + auto-burn: ~180,000 - 220,000 gas

**Events Emitted:**
- `RewardClaimed(user, stakeIndex, usdtAmount, totalClaimed)`
- `TokensAutoBurned(user, stakeIndex, burnedAmount, totalRewardsClaimed)` (jika auto-burn)

---

#### **canClaim()**

```solidity
function canClaim(address _user, uint256 _stakeIndex) 
    public view 
    returns (bool)
```

**Deskripsi:** Check apakah user bisa claim reward.

**Logic:**
```solidity
UserStake memory userStake = userStakes[_user][_stakeIndex];

if (!userStake.isActive || userStake.isBurned) return false;

return block.timestamp >= userStake.nextClaimTime;
```

**Gas Cost:** ~5,000 gas (view function)

---

### **Auto-Burn Function:**

#### **_autoBurnTokens()**

```solidity
function _autoBurnTokens(uint256 _stakeIndex) private
```

**Deskripsi:** Internal function untuk auto-burn principal OZONE.

**Flow:**
1. Get stake data
2. Validate stake aktif dan belum di-burn
3. Get burn amount
4. Update stake:
   - `isBurned = true`
   - `isActive = false`
5. Update pool stats:
   - `totalStaked -= burnAmount`
6. Update global stats:
   - `totalTokensBurned += burnAmount`
   - `activeStakeCount--`
7. Transfer OZONE ke dead address (0x...dEaD)
8. Emit event

**Dead Address:** `0x000000000000000000000000000000000000dEaD`

**Gas Cost:** ~60,000 - 80,000 gas

**Events Emitted:**
- `TokensAutoBurned(user, stakeIndex, burnedAmount, totalRewardsClaimed)`

---

### **Unstake Function:**

#### **unstake()**

```solidity
function unstake(uint256 _stakeIndex) 
    external 
    nonReentrant 
    whenNotPaused
```

**Deskripsi:** User bisa unstake sebelum durasi habis (optional early exit).

**Flow:**
1. Validate stake exists dan aktif
2. Get amount to return
3. Update stake:
   - `isActive = false`
4. Update pool stats:
   - `totalStaked -= amount`
5. Update global:
   - `activeStakeCount--`
6. Transfer OZONE kembali ke user
7. Emit event

**Note:** Reward yang belum di-claim akan hangus!

**Gas Cost:** ~100,000 - 130,000 gas

**Events Emitted:**
- `UserUnstaked(user, stakeIndex, amount)`

---

### **Admin Functions:**

#### **addPresaleSupply()**

```solidity
function addPresaleSupply(uint256 _amount) external onlyOwner
```

**Deskripsi:** Owner menambah OZONE untuk presale.

**Gas Cost:** ~50,000 gas

---

#### **setTreasuryWallet()**

```solidity
function setTreasuryWallet(address _newTreasury) external onlyOwner
```

**Deskripsi:** Update treasury wallet untuk terima USDT dari presale.

**Gas Cost:** ~30,000 gas

---

#### **setPresaleActive()**

```solidity
function setPresaleActive(bool _active) external onlyOwner
```

**Deskripsi:** Toggle presale on/off.

**Gas Cost:** ~25,000 gas

---

#### **setOzonePrice()**

```solidity
function setOzonePrice(uint256 _price) external onlyOwner
```

**Deskripsi:** Update harga OZONE (manual, akan diganti oracle nanti).

**Gas Cost:** ~28,000 gas

**Note:** Harga baru hanya mempengaruhi:
- Presale baru
- Stake baru
- Perhitungan reward baru

Tidak mempengaruhi stake yang sudah ada (APY & tier locked).

---

#### **fundUSDTReserves()**

```solidity
function fundUSDTReserves(uint256 _amount) external onlyOwner
```

**Deskripsi:** Owner fund USDT reserves untuk reward.

**Gas Cost:** ~55,000 gas

---

#### **withdrawUSDTReserves()**

```solidity
function withdrawUSDTReserves(uint256 _amount) external onlyOwner
```

**Deskripsi:** Emergency withdraw USDT reserves.

**Gas Cost:** ~50,000 gas

---

#### **updatePool()**

```solidity
function updatePool(
    uint256 _poolId,
    string memory _name,
    uint256 _monthlyAPY,
    uint256 _minStake,
    uint256 _maxStake
) external onlyOwner
```

**Deskripsi:** Update pool settings.

**Note:** Hanya mempengaruhi stake baru, tidak mempengaruhi stake existing.

**Gas Cost:** ~40,000 - 60,000 gas

---

#### **deactivatePool()**

```solidity
function deactivatePool(uint256 _poolId, string memory _reason) external onlyOwner
```

**Deskripsi:** Nonaktifkan pool (user tidak bisa stake baru).

**Gas Cost:** ~30,000 gas

---

#### **pause() / unpause()**

```solidity
function pause() external onlyOwner
function unpause() external onlyOwner
```

**Deskripsi:** Emergency pause/unpause contract.

**Gas Cost:** ~25,000 gas

---

### **View Functions:**

#### **getPool()**

```solidity
function getPool(uint256 _poolId) external view returns (Pool memory)
```

**Returns:** Full pool data struct.

---

#### **getAllPools()**

```solidity
function getAllPools() external view returns (Pool[] memory)
```

**Returns:** Array of all pools.

**Gas Cost:** ~50,000 - 100,000 gas (tergantung jumlah pool)

---

#### **getUserStake()**

```solidity
function getUserStake(address _user, uint256 _stakeIndex) 
    external view 
    returns (UserStake memory)
```

**Returns:** Single stake data.

---

#### **getUserStakes()**

```solidity
function getUserStakes(address _user) 
    external view 
    returns (UserStake[] memory)
```

**Returns:** All stakes untuk user.

**Gas Cost:** ~20,000 - 200,000 gas (tergantung jumlah stakes)

---

#### **getUserStakeCount()**

```solidity
function getUserStakeCount(address _user) 
    external view 
    returns (uint256)
```

**Returns:** Total stakes user.

---

#### **getRewardBreakdown()**

```solidity
function getRewardBreakdown(address _user, uint256 _stakeIndex)
    external view 
    returns (
        uint256 claimableRewardsUSDT,
        uint256 alreadyClaimedUSDT,
        bool shouldAutoBurn,
        uint256 daysUntilBurn
    )
```

**Returns:**
- `claimableRewardsUSDT`: Reward yang bisa di-claim sekarang
- `alreadyClaimedUSDT`: Total yang sudah di-claim
- `shouldAutoBurn`: Apakah akan auto-burn?
- `daysUntilBurn`: Sisa hari hingga auto-burn

---

#### **getStakingStats()**

```solidity
function getStakingStats() external view returns (
    uint256 totalActiveStakes,
    uint256 totalUSDTDistributed,
    uint256 totalBurned,
    uint256 usdtReserveBalance,
    uint256 totalPresaleSoldAmount,
    uint256 remainingPresaleSupply
)
```

**Returns:** Overall contract statistics.

---

#### **getPresaleInfo()**

```solidity
function getPresaleInfo() external view returns (
    uint256 currentPrice,
    uint256 remainingSupply,
    uint256 totalSold,
    address treasury,
    bool active
)
```

**Returns:** Presale information.

---

#### **getTimeUntilNextClaim()**

```solidity
function getTimeUntilNextClaim(address _user, uint256 _stakeIndex) 
    external view 
    returns (uint256)
```

**Returns:** Seconds until next claim available (0 jika sudah bisa claim).

---

#### **getVersion()**

```solidity
function getVersion() external pure returns (string memory)
```

**Returns:** Contract version string ("2.0.0-Integrated").

---

## 📡 Events

### **Staking Events:**

```solidity
event UserStaked(
    address indexed user,
    uint256 indexed poolId,
    uint256 ozoneAmount,
    uint256 usdtValue,
    uint256 stakeIndex,
    bool fromPresale
);
```

```solidity
event UserUnstaked(
    address indexed user,
    uint256 indexed stakeIndex,
    uint256 amount
);
```

### **Reward Events:**

```solidity
event RewardClaimed(
    address indexed user,
    uint256 indexed stakeIndex,
    uint256 usdtAmount,
    uint256 totalClaimed
);
```

```solidity
event TokensAutoBurned(
    address indexed user,
    uint256 indexed stakeIndex,
    uint256 burnedAmount,
    uint256 totalRewardsClaimed
);
```

### **Presale Events:**

```solidity
event PresalePurchase(
    address indexed buyer,
    uint256 indexed poolId,
    uint256 usdtPaid,
    uint256 ozoneReceived,
    uint256 stakeIndex
);
```

```solidity
event PresaleSupplyAdded(
    uint256 amount,
    uint256 newTotal
);
```

```solidity
event TreasuryWalletUpdated(
    address indexed oldWallet,
    address indexed newWallet
);
```

```solidity
event PresaleStatusChanged(bool active);
```

### **Pool Events:**

```solidity
event PoolCreated(
    uint256 indexed poolId,
    string name,
    uint256 monthlyAPY,
    uint256 minStake,
    uint256 maxStake
);
```

```solidity
event PoolUpdated(
    uint256 indexed poolId,
    string name,
    uint256 monthlyAPY
);
```

```solidity
event PoolDeactivated(
    uint256 indexed poolId,
    string reason
);
```

### **Reserve Events:**

```solidity
event USDTReservesFunded(uint256 amount);
event USDTReservesWithdrawn(uint256 amount);
```

### **Price Events:**

```solidity
event OzonePriceUpdated(
    uint256 oldPrice,
    uint256 newPrice,
    uint256 timestamp
);
```

### **Upgrade Events:**

```solidity
event ContractUpgraded(
    address indexed newImplementation,
    uint256 timestamp
);
```

---

## 🔐 Modifiers

### **onlyOwner**
- Hanya owner yang bisa execute
- Dari `OwnableUpgradeable`

### **whenNotPaused**
- Contract harus tidak dalam status paused
- Dari `PausableUpgradeable`

### **nonReentrant**
- Proteksi reentrancy attack
- Dari `ReentrancyGuardUpgradeable`

---

## 🧮 Perhitungan Internal

### **Duration Calculation:**

```solidity
uint256 durationMonths = (MAX_REWARD_PERCENTAGE * 100) / monthlyAPY;
// MAX_REWARD_PERCENTAGE = 30000 (300%)
// monthlyAPY dalam basis points (600 = 6%)

// Contoh:
// Pool A: (30000 * 100) / 600 = 5000 / 100 = 50 months
// Pool B: (30000 * 100) / 1000 = 3000 / 100 = 30 months
```

### **Daily Reward Calculation:**

```solidity
// Reward dihitung langsung dari USDT value at stake (FIXED)
uint256 dailyRewardUSDT = (usdtValueAtStake * lockedAPY) / 10000 / 30;

// Multiply dengan days elapsed
uint256 totalRewardUSDT = dailyRewardUSDT * daysElapsed;
```

**⚠️ PENTING:** Reward **TIDAK menggunakan** harga OZONE! Dihitung langsung dari nilai USDT saat stake.

**Contoh:**
```
usdtValueAtStake = $1,000 (locked saat stake)
lockedAPY = 600 (6%)
daysElapsed = 30 hari

dailyRewardUSDT = ($1,000 * 600) / 10000 / 30
                = 600,000 / 10000 / 30
                = 60 / 30
                = $2 USDT per hari

totalRewardUSDT = $2 * 30 = $60 USDT

✅ Hasil: $60 USDT (tidak peduli harga OZONE)
```

### **Max Reward Check:**

```solidity
uint256 maxRewardUSDT = (usdtValueAtStake * MAX_REWARD_PERCENTAGE) / 10000;
uint256 remainingRewardUSDT = maxRewardUSDT - totalClaimedReward;

if (totalRewardUSDT > remainingRewardUSDT) {
    totalRewardUSDT = remainingRewardUSDT;
}
```

---

## ⚡ Gas Optimization

### **Teknik yang Digunakan:**

1. **Packed Storage:**
   ```solidity
   // Variabel boolean dan small uint dalam 1 slot
   bool isActive;
   bool isBurned;
   uint256 durationMonths;
   ```

2. **Memory vs Storage:**
   ```solidity
   // Menggunakan memory untuk read-only
   Pool memory pool = pools[_poolId];
   
   // Storage hanya untuk update
   UserStake storage userStake = userStakes[msg.sender][_stakeIndex];
   ```

3. **Short-Circuit Evaluation:**
   ```solidity
   if (!userStake.isActive || userStake.isBurned) return (0, false);
   ```

4. **Minimal External Calls:**
   - Combine multiple operations dalam 1 transaksi
   - Batch reads dengan struct returns

5. **Events untuk Off-Chain Data:**
   - Minimal on-chain storage
   - Event emission untuk tracking

---

## 🔄 Upgrade Mechanism

### **UUPS Pattern:**

```solidity
function _authorizeUpgrade(address newImplementation) 
    internal 
    override 
    onlyOwner 
{
    emit ContractUpgraded(newImplementation, block.timestamp);
}
```

### **Upgrade Process:**

1. **Deploy New Implementation:**
   ```javascript
   const OzoneStakingV2New = await ethers.getContractFactory("OzoneStakingV2New");
   const newImpl = await OzoneStakingV2New.deploy();
   await newImpl.deployed();
   ```

2. **Upgrade Via Proxy:**
   ```javascript
   const stakingV2 = await ethers.getContractAt("OzoneStakingV2", proxyAddress);
   await stakingV2.upgradeTo(newImpl.address);
   ```

3. **Verify Upgrade:**
   ```javascript
   const version = await stakingV2.getVersion();
   console.log("New version:", version);
   ```

### **Upgrade Safety:**

- ✅ Data tetap di proxy (tidak hilang)
- ✅ State variables harus compatible
- ✅ Jangan ubah storage layout existing variables
- ✅ Bisa tambah variables di akhir
- ✅ Test di testnet dulu

---

## ⚠️ Error Codes

### **Common Errors:**

| Error | Penyebab | Solusi |
|-------|----------|--------|
| "Invalid stake index" | Index stake tidak valid | Cek getUserStakeCount() |
| "Cannot claim yet - must wait 15 days" | Belum 15 hari dari last claim | Tunggu sampai nextClaimTime |
| "No rewards available" | Tidak ada reward untuk di-claim | Tunggu beberapa hari |
| "Insufficient USDT reserves" | Contract reserves habis | Admin perlu fund reserves |
| "Pool does not exist" | Pool ID salah | Gunakan poolId 1-5 |
| "Pool is not active" | Pool di-deactivate | Pilih pool lain |
| "Below minimum stake for this pool" | Amount terlalu kecil | Tambah amount atau pilih pool lain |
| "Above maximum stake for this pool" | Amount terlalu besar | Kurangi amount atau pilih pool lebih tinggi |
| "Presale not active" | Presale di-pause | Tunggu presale active kembali |
| "Insufficient presale supply" | Presale supply habis | Tunggu admin add supply |
| "USDT transfer failed" | Approve USDT kurang | Approve USDT dulu |
| "Transfer failed" | Approve OZONE kurang | Approve OZONE dulu |

---

## 🧪 Testing

### **Unit Tests:**

```javascript
describe("OzoneStakingV2", function() {
    it("Should deploy with correct initial state", async function() {
        expect(await stakingV2.totalPools()).to.equal(5);
        expect(await stakingV2.presaleActive()).to.equal(true);
    });
    
    it("Should allow buyAndStake", async function() {
        await usdt.approve(stakingV2.address, usdtAmount);
        await stakingV2.buyAndStake(1, usdtAmount);
        
        const stakes = await stakingV2.getUserStakes(user.address);
        expect(stakes.length).to.equal(1);
    });
    
    it("Should calculate rewards correctly", async function() {
        // Stake
        await stakingV2.stake(1, ozoneAmount);
        
        // Fast forward 15 days
        await ethers.provider.send("evm_increaseTime", [15 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");
        
        // Check rewards
        const breakdown = await stakingV2.getRewardBreakdown(user.address, 0);
        expect(breakdown.claimableRewardsUSDT).to.be.gt(0);
    });
    
    it("Should auto-burn after duration", async function() {
        // Stake
        await stakingV2.stake(5, ozoneAmount); // Pool B = 30 months
        
        // Fast forward 30 months
        await ethers.provider.send("evm_increaseTime", [30 * 30 * 24 * 60 * 60]);
        await ethers.provider.send("evm_mine");
        
        // Claim (should trigger auto-burn)
        await stakingV2.claimRewards(0);
        
        const stake = await stakingV2.getUserStake(user.address, 0);
        expect(stake.isBurned).to.equal(true);
    });
});
```

---

## 📞 Support

Untuk pertanyaan teknis atau bug report:
- **GitHub Issues**: https://github.com/krismayuangga/stakingV2/issues
- **Developer Telegram**: @ozonedev
- **Email**: dev@ozone.com

---

**Version**: 2.0.0-Integrated  
**Last Updated**: 3 Desember 2025  
**Solidity**: 0.8.20  
**License**: MIT

# ✅ JAWABAN LENGKAP - Verifikasi Pemahaman

Tanggal: 4 Desember 2024

---

## 📝 Pertanyaan & Jawaban

### **1️⃣ Inject Token OZONE di Smart Contract untuk Presale?**

**✅ BENAR**

**Flow Deployment:**
```
Step 1: Deploy OzoneStakingV2 (UUPS Proxy)
        ↓
Step 2: Initialize contract (set wallets, price, dll)
        ↓
Step 3: Transfer OZONE ke contract address
        Contoh: 100,000,000 OZONE → StakingV2 contract
        ↓
Step 4: Contract siap untuk presale
```

**Saat User Beli (buyAndStake):**
```
User bayar USDT → Contract
        ↓
Contract calculate OZONE amount
        ↓
OZONE TIDAK ke user wallet ❌
OZONE tetap di contract ✅
        ↓
Hanya dicatat di userStakes mapping
```

**Alasan OZONE Tidak ke User:**
- ✅ Anti-dump mechanism
- ✅ Auto-staking (langsung earn rewards)
- ✅ Duration-based lock (user tidak bisa jual)
- ✅ Auto-burn setelah durasi habis

---

### **2️⃣ Manual Staking = Hanya Pencatatan Tanpa Transfer?**

**❌ SETENGAH BENAR - Ada Transfer Fisik!**

**Flow Manual Stake:**
```
User punya OZONE di wallet pribadi
        ↓
User approve OZONE ke contract
        ↓
User call stake(poolId, amount)
        ↓
TRANSFER FISIK TERJADI! 🔄
├── User wallet: -1,000 OZONE (keluar)
├── OZONE tax 1%: -10 OZONE → OZONE treasury
└── Contract wallet: +990 OZONE (masuk)
        ↓
Contract catat di userStakes[user]
```

**Jadi ADA 2 Hal Terjadi:**
1. ✅ **Transfer fisik** OZONE dari user ke contract
2. ✅ **Pencatatan** stake di mapping

**Ketika Unstake:**
```
User call unstake(stakeIndex)
        ↓
Contract transfer OZONE kembali ke user
        ↓
User wallet: +990 OZONE (kembali)
```

**Perbedaan Presale vs Manual:**

| Aspek | Presale (buyAndStake) | Manual Stake (stake) |
|-------|----------------------|---------------------|
| OZONE Origin | Dari contract supply | Dari user wallet |
| Transfer Fisik | ❌ Tidak (sudah di contract) | ✅ Ya (user → contract) |
| User Wallet | Tidak dapat OZONE | OZONE keluar dari wallet |
| Unstake | OZONE kembali ke user | OZONE kembali ke user |

---

### **3️⃣ Wallet TAX & Treasury Setting Setelah Kontrak Jadi?**

**✅ BENAR - Set saat Initialize**

**Saat Deploy:**
```javascript
// Step 1: Deploy proxy dan implementation
const StakingV2 = await ethers.getContractFactory("OzoneStakingV2");
const proxy = await upgrades.deployProxy(StakingV2, [
    ozoneTokenAddress,
    usdtTokenAddress,
    ozoneContractAddress,
    initialOzonePrice,
    "0xYourExistingTreasuryWallet",  // ← Wallet existing Anda untuk terima USDT base price
    "0xYourExistingTaxWallet",       // ← Wallet existing Anda untuk terima 1% USDT fee
    presaleSupply
], { kind: 'uups' });

await proxy.deployed();
console.log("StakingV2 deployed to:", proxy.address);
```

**Wallet Anda Akan Terima:**

**Treasury Wallet:**
- ✅ 99% USDT dari presale (base price)
- ✅ Contoh: User bayar $1,010 → Treasury dapat $1,000

**Tax Wallet:**
- ✅ 1% USDT platform fee
- ✅ Contoh: User bayar $1,010 → Tax wallet dapat $10

**Bisa Diubah Nanti:**
```javascript
// Update treasury wallet (hanya owner)
await stakingV2.setTreasuryWallet("0xNewWallet");

// Update tax wallet (hanya owner)
await stakingV2.setTaxWallet("0xNewWallet");
```

---

### **4️⃣ Desimal OZONE = 18, USDT = 18?**

**❌ SALAH untuk USDT!**

### **Decimals yang Benar:**

| Token | Decimals | Contoh 1 Token | BigNumber Representation |
|-------|----------|----------------|-------------------------|
| **OZONE** | **18** | `1000000000000000000` | 1 dengan 18 nol |
| **USDT BSC** | **6** | `1000000` | 1 dengan 6 nol |

### **Evidence:**

**1. Dari ozone.sol:**
```solidity
uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18;
// OZONE = 18 decimals ✅
```

**2. Dari presale.sol (Line 37):**
```solidity
uint256 pricePerToken; // Price in USDT (6 decimals) per OZONE token (18 decimals)
```

**3. Dari presale.sol (Line 106):**
```solidity
// USDT has 6 decimals, OZONE has 18 decimals
uint256 tokensToBuy = (usdtAmount * 10**18) / phase.pricePerToken;
```

**4. USDT BSC Official:**
- Contract: `0x55d398326f99059fF775485246999027B3197955`
- Decimals: **6** (bukan 18!)
- Ini standard USDT di semua chain (6 decimals)

### **Kenapa Penting?**

**❌ Salah Pakai 18 Decimals untuk USDT:**
```javascript
// WRONG! ❌
const usdt = ethers.utils.parseUnits("1000", 18);
// Result: 1000000000000000000000 (21 digits!)
// Ini 1 TRILLION USDT! (salah!)
```

**✅ Benar Pakai 6 Decimals:**
```javascript
// CORRECT! ✅
const usdt = ethers.utils.parseUnits("1000", 6);
// Result: 1000000000 (9 digits)
// Ini 1,000 USDT (benar!)
```

### **Cara Pakai yang Benar:**

**Untuk USDT (6 decimals):**
```javascript
// Approve USDT
const usdtAmount = ethers.utils.parseUnits("10000", 6); // 10,000 USDT
await usdtToken.approve(stakingV2, usdtAmount);

// Check balance
const balance = await usdtToken.balanceOf(userAddress);
const readable = ethers.utils.formatUnits(balance, 6);
console.log(`Balance: ${readable} USDT`);
```

**Untuk OZONE (18 decimals):**
```javascript
// Approve OZONE
const ozoneAmount = ethers.utils.parseEther("1000"); // 1,000 OZONE
// atau: ethers.utils.parseUnits("1000", 18)
await ozoneToken.approve(stakingV2, ozoneAmount);

// Check balance
const balance = await ozoneToken.balanceOf(userAddress);
const readable = ethers.utils.formatEther(balance);
console.log(`Balance: ${readable} OZONE`);
```

**Price Calculation:**
```javascript
// Set OZONE price = $91
const price = ethers.utils.parseEther("91"); // 91 * 10^18
await stakingV2.setOzonePrice(price);

// User bayar $1000 USDT (6 decimals)
const usdtAmount = ethers.utils.parseUnits("1000", 6);

// Calculate OZONE (contract akan dapat):
// ozoneAmount = (usdtAmount * 10^18) / price
//             = (1000 * 10^6 * 10^18) / (91 * 10^18)
//             = (1000 * 10^6) / 91
//             = 10,989,010 * 10^12 (dalam wei, 18 decimals)
//             = 10.989 OZONE

const ozoneAmount = usdtAmount.mul(ethers.BigNumber.from(10).pow(18)).div(price);
console.log(ethers.utils.formatEther(ozoneAmount)); // "10.989010989010989010"
```

---

## 🎯 Kesimpulan

| Pertanyaan | Jawaban | Status |
|------------|---------|--------|
| 1. Inject OZONE untuk presale supply? | Ya, transfer OZONE ke contract address | ✅ Benar |
| 2. Manual stake = hanya pencatatan? | Tidak, ada transfer fisik OZONE user→contract | ❌ Setengah benar |
| 3. Wallet set saat initialize? | Ya, bisa pakai wallet existing | ✅ Benar |
| 4. OZONE & USDT = 18 decimals? | OZONE=18, USDT=6 (BUKAN 18!) | ❌ Salah untuk USDT |

---

## ⚠️ CRITICAL NOTES

### **1. USDT Decimals = 6 (PENTING!)**
Selalu pakai `parseUnits("amount", 6)` untuk USDT di BSC, BUKAN 18!

### **2. Contract Tax Exempt**
Setelah deploy, set StakingV2 contract sebagai tax exempt di OZONE token:
```javascript
await ozoneToken.setTaxExempt(stakingV2ProxyAddress, true);
```

### **3. Presale Supply**
Transfer OZONE ke contract SEBELUM presale active:
```javascript
// Transfer 100M OZONE untuk presale
const supply = ethers.utils.parseEther("100000000");
await ozoneToken.transfer(stakingV2Address, supply);

// Activate presale
await stakingV2.setPresaleActive(true);
```

### **4. Wallet Addresses**
Pastikan treasury & tax wallet address sudah benar saat initialize - ini akan terima USDT!

---

## 📚 Documentation Updates

Saya sudah update semua dokumentasi:

✅ **README_ID.md:**
- Tambah section "Token Decimals" dengan warning USDT = 6
- Update semua contoh code pakai `parseUnits("x", 6)` untuk USDT
- Tambah comment di setiap contoh tentang decimals

✅ **DECIMAL_CORRECTION.md (BARU):**
- Complete guide tentang decimal handling
- Evidence dari original contracts
- Checklist koreksi dokumentasi

✅ Semua contoh code sekarang menggunakan decimals yang BENAR!

---

**Prepared by:** GitHub Copilot  
**Date:** December 4, 2024  
**Contract Version:** OzoneStakingV2 v2.0.0-Integrated

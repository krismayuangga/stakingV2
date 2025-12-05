# 🚀 OzoneStakingV2 - Deployment Guide

## 📋 Prerequisites

1. **Testnet BNB**: Get from [BSC Testnet Faucet](https://testnet.bnbchain.org/faucet-smart)
2. **Existing Tokens** (BSC Testnet):
   - OZONE: `0x21144E5CA7e6324840e46FeCF33f67232A9c728b`
   - USDT Mock: `0x7419b623cD6AF200896e4445F7647f548236876E`
3. **Metamask**: Connected to BSC Testnet
4. **Node.js**: v16+ installed

## 🔧 Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
```bash
# Copy example env file
cp .env.example .env

# Edit .env with your values
notepad .env
```

Required in `.env`:
```env
PRIVATE_KEY=your_private_key_here
BSCSCAN_API_KEY=your_bscscan_api_key
TREASURY_WALLET=your_treasury_address
TAX_WALLET=your_tax_address
```

### 3. Get BscScan API Key
1. Go to https://testnet.bscscan.com/myapikey
2. Create account and generate API key
3. Add to `.env`

## 🚀 Deployment Steps

### Step 1: Deploy Contract
```bash
npx hardhat run scripts/deploy.js --network bscTestnet
```

This will:
- Deploy UUPS Proxy + Implementation
- Initialize with 5 pool tiers
- Set presaleActive to `false` by default
- Output proxy and implementation addresses

**Save the proxy address** - you'll need it!

### Step 2: Verify on BscScan
```bash
# Use implementation address from deployment output
npx hardhat verify --network bscTestnet <IMPLEMENTATION_ADDRESS>
```

### Step 3: Fund Contract with OZONE
```bash
# Transfer OZONE tokens to proxy address
# Amount: initialPresaleSupply (default 10M OZONE)
```

Via Metamask or script:
```javascript
// In Hardhat console or script
const ozone = await ethers.getContractAt("IERC20", "0x21144E5CA7e6324840e46FeCF33f67232A9c728b");
await ozone.transfer("PROXY_ADDRESS", ethers.parseEther("10000000"));
```

### Step 4: Fund USDT Reserves
```bash
# Transfer USDT to contract for rewards
# Recommended: 300% of expected sales
# Example: $100k sales = $300k USDT reserves
```

Via contract function:
```javascript
const usdt = await ethers.getContractAt("IERC20", "0x7419b623cD6AF200896e4445F7647f548236876E");
const staking = await ethers.getContractAt("OzoneStakingV2", "PROXY_ADDRESS");

// Approve
await usdt.approve("PROXY_ADDRESS", ethers.parseEther("300000"));

// Fund
await staking.fundUSDTReserves(ethers.parseEther("300000"));
```

### Step 5: Activate Presale
```bash
# Edit scripts/setup.js - add your PROXY_ADDRESS
npx hardhat run scripts/setup.js --network bscTestnet
```

Or manually:
```javascript
const staking = await ethers.getContractAt("OzoneStakingV2", "PROXY_ADDRESS");
await staking.setPresaleActive(true);
```

## ✅ Verification Checklist

After deployment, verify:

- [ ] Contract verified on BscScan
- [ ] OZONE tokens in contract >= presaleSupply
- [ ] USDT reserves funded (minimum $300k recommended)
- [ ] Presale activated (`presaleActive == true`)
- [ ] 5 pools initialized correctly
- [ ] Treasury wallet set correctly
- [ ] Tax wallet set correctly
- [ ] OZONE price set (via `setOzonePrice()`)

## 📊 Contract Interaction

### View Functions (Free)
```javascript
// Get contract overview
await staking.getContractOverview();

// Get pool info
await staking.getPool(1); // Pool ID 1-5

// Get user stakes
await staking.getUserStakes(userAddress);

// Check if user can claim
await staking.canClaim(userAddress, stakeIndex);
```

### User Functions (Requires Gas)
```javascript
// Buy and stake
await staking.buyAndStake(poolId, usdtAmount);

// Claim rewards (after 15 days)
await staking.claimRewards(stakeIndex);

// Claim all rewards (batch)
await staking.claimAllRewards();
```

### Admin Functions (Owner Only)
```javascript
// Update OZONE price
await staking.setOzonePrice(ethers.parseEther("0.015")); // $0.015

// Fund reserves
await staking.fundUSDTReserves(amount);

// Pause/unpause
await staking.pause();
await staking.unpause();

// Update pool
await staking.updatePool(poolId, name, apy, minStake, maxStake);
```

## 🔄 Upgrading Contract

```bash
# Edit scripts/upgrade.js - add your PROXY_ADDRESS
npx hardhat run scripts/upgrade.js --network bscTestnet
```

UUPS proxy allows upgrades while preserving:
- All user stakes
- Presale data
- Pool configurations
- Contract state

## 🧪 Testing on Testnet

1. Get testnet USDT from faucet or mint
2. Approve USDT to contract
3. Call `buyAndStake(1, ethers.parseEther("100"))`
4. Wait 15 days (or time-travel in test)
5. Call `claimRewards(0)`
6. Verify USDT rewards received

## 📱 Frontend Integration

Contract ABI available in: `artifacts/contracts/OzoneStakingV2.sol/OzoneStakingV2.json`

Key functions for frontend:
- `getContractOverview()` - All data in 1 call
- `getAllPools()` - Pool information
- `getUserStakes(address)` - User's stakes
- `getRewardBreakdown(address, index)` - Detailed rewards
- `canClaim(address, index)` - Claim eligibility

## 🔗 Useful Links

- **BSC Testnet Explorer**: https://testnet.bscscan.com
- **BSC Testnet Faucet**: https://testnet.bnbchain.org/faucet-smart
- **Hardhat Docs**: https://hardhat.org/docs
- **OpenZeppelin Upgrades**: https://docs.openzeppelin.com/upgrades-plugins

## 🆘 Troubleshooting

### "Insufficient OZONE balance" error
- Transfer OZONE tokens to contract before activating presale
- Check: `ozoneToken.balanceOf(proxyAddress) >= presaleSupply`

### "Insufficient USDT reserves" error
- Fund contract with USDT via `fundUSDTReserves()`
- Reserves needed: 300% of total sales

### Verification fails
- Make sure you verify the **implementation** address, not proxy
- Use exact compiler version: 0.8.22
- Enable optimizer with 200 runs

### Transaction fails
- Check you have enough testnet BNB for gas
- Verify contract is not paused
- Check user has approved USDT to contract

## 📞 Support

For issues or questions, create an issue on GitHub or contact the team.

## ⚠️ Security Notes

- **NEVER** commit `.env` file to git
- **ALWAYS** test on testnet before mainnet
- **VERIFY** all addresses before transferring funds
- **AUDIT** contract before mainnet deployment
- **BACKUP** private keys securely

---

**Ready for Production?**
1. All tests passing ✅
2. Deployed on testnet ✅
3. Tested user flow ✅
4. Security audited ✅
5. Frontend integrated ✅

**Then deploy to BSC Mainnet with same process!**

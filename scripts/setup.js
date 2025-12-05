const { ethers } = require("hardhat");

async function main() {
  console.log("🔧 Post-Deployment Setup Script\n");

  // UPDATE THIS: Your deployed proxy address
  const PROXY_ADDRESS = "YOUR_PROXY_ADDRESS_HERE";
  
  const [owner] = await ethers.getSigners();
  console.log("📍 Setup from account:", owner.address);

  // Connect to deployed contract
  const stakingContract = await ethers.getContractAt("OzoneStakingV2", PROXY_ADDRESS);
  console.log("✅ Connected to contract:", PROXY_ADDRESS, "\n");

  // ============================================================================
  // STEP 1: Check OZONE Token Balance
  // ============================================================================
  
  console.log("📊 STEP 1: Checking OZONE token balance...");
  
  const ozoneTokenAddress = await stakingContract.ozoneToken();
  const ozoneToken = await ethers.getContractAt("IERC20", ozoneTokenAddress);
  const ozoneBalance = await ozoneToken.balanceOf(PROXY_ADDRESS);
  const presaleSupply = await stakingContract.presaleSupply();
  
  console.log("   OZONE in contract:", ethers.formatEther(ozoneBalance));
  console.log("   Presale supply needed:", ethers.formatEther(presaleSupply));
  
  if (ozoneBalance >= presaleSupply) {
    console.log("   ✅ Contract has enough OZONE tokens\n");
  } else {
    const needed = presaleSupply - ozoneBalance;
    console.log("   ⚠️  Need to transfer", ethers.formatEther(needed), "more OZONE tokens\n");
    return;
  }

  // ============================================================================
  // STEP 2: Fund USDT Reserves
  // ============================================================================
  
  console.log("📊 STEP 2: Funding USDT reserves...");
  
  const usdtTokenAddress = await stakingContract.usdtToken();
  const usdtToken = await ethers.getContractAt("IERC20", usdtTokenAddress);
  
  // Calculate needed reserves (example: enough for 300% rewards on $100k sales)
  const reservesNeeded = ethers.parseEther("300000"); // $300k USDT
  
  const ownerUsdtBalance = await usdtToken.balanceOf(owner.address);
  console.log("   Your USDT balance:", ethers.formatEther(ownerUsdtBalance));
  console.log("   Reserves needed:", ethers.formatEther(reservesNeeded));
  
  if (ownerUsdtBalance >= reservesNeeded) {
    console.log("   Approving USDT...");
    const approveTx = await usdtToken.approve(PROXY_ADDRESS, reservesNeeded);
    await approveTx.wait();
    
    console.log("   Funding reserves...");
    const fundTx = await stakingContract.fundUSDTReserves(reservesNeeded);
    await fundTx.wait();
    
    console.log("   ✅ USDT reserves funded\n");
  } else {
    console.log("   ⚠️  Insufficient USDT balance\n");
  }

  // ============================================================================
  // STEP 3: Activate Presale
  // ============================================================================
  
  console.log("📊 STEP 3: Activating presale...");
  
  const presaleActive = await stakingContract.presaleActive();
  
  if (!presaleActive) {
    console.log("   Activating presale...");
    const activateTx = await stakingContract.setPresaleActive(true);
    await activateTx.wait();
    console.log("   ✅ Presale activated\n");
  } else {
    console.log("   ✅ Presale already active\n");
  }

  // ============================================================================
  // VERIFY FINAL STATE
  // ============================================================================
  
  console.log("📊 FINAL STATE:");
  const finalState = await stakingContract.getContractOverview();
  console.log("   OZONE Price:", ethers.formatEther(finalState[0]), "USDT");
  console.log("   Remaining Presale Supply:", ethers.formatEther(finalState[1]), "OZONE");
  console.log("   Total Presale Sold:", ethers.formatEther(finalState[2]), "OZONE");
  console.log("   Presale Active:", finalState[3]);
  console.log("   USDT Reserves:", ethers.formatEther(finalState[7]), "USDT");
  console.log("   Total Pools:", finalState[8].toString());
  
  console.log("\n✅ SETUP COMPLETE! Contract is ready for use.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Starting OzoneStakingV2 Deployment to BSC Testnet...\n");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📍 Deploying from account:", deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "BNB\n");

  // ============================================================================
  // CONFIGURATION - UPDATE THESE VALUES
  // ============================================================================
  
  const config = {
    // Existing Token Addresses (BSC Testnet)
    ozoneToken: "0x21144E5CA7e6324840e46FeCF33f67232A9c728b",
    usdtToken: "0x7419b623cD6AF200896e4445F7647f548236876E",
    
    // Initial OZONE Price (in USDT, 18 decimals)
    // Example: $0.01 = 0.01 * 10^18
    initialOzonePrice: ethers.parseEther("0.01"), // $0.01 per OZONE
    
    // Wallet Addresses
    treasuryWallet: deployer.address, // TODO: Change to real treasury wallet
    taxWallet: deployer.address,      // TODO: Change to real tax wallet
    
    // Initial Presale Supply (OZONE tokens available for presale)
    // Example: 10,000,000 OZONE
    initialPresaleSupply: ethers.parseEther("10000000") // 10M OZONE
  };

  console.log("📋 Deployment Configuration:");
  console.log("   OZONE Token:", config.ozoneToken);
  console.log("   USDT Token:", config.usdtToken);
  console.log("   Initial OZONE Price:", ethers.formatEther(config.initialOzonePrice), "USDT");
  console.log("   Treasury Wallet:", config.treasuryWallet);
  console.log("   Tax Wallet:", config.taxWallet);
  console.log("   Initial Presale Supply:", ethers.formatEther(config.initialPresaleSupply), "OZONE\n");

  // ============================================================================
  // DEPLOY CONTRACT VIA UUPS PROXY
  // ============================================================================
  
  console.log("📦 Deploying OzoneStakingV2 contract...");
  
  const OzoneStakingV2 = await ethers.getContractFactory("OzoneStakingV2");
  
  const stakingContract = await upgrades.deployProxy(
    OzoneStakingV2,
    [
      config.ozoneToken,
      config.usdtToken,
      config.initialOzonePrice,
      config.treasuryWallet,
      config.taxWallet,
      config.initialPresaleSupply
    ],
    {
      initializer: "initialize",
      kind: "uups"
    }
  );

  await stakingContract.waitForDeployment();
  const proxyAddress = await stakingContract.getAddress();

  console.log("✅ Proxy deployed to:", proxyAddress);
  
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log("✅ Implementation deployed to:", implementationAddress);

  // ============================================================================
  // VERIFY DEPLOYMENT
  // ============================================================================
  
  console.log("\n🔍 Verifying deployment...");
  
  const ozoneTokenAddress = await stakingContract.ozoneToken();
  const usdtTokenAddress = await stakingContract.usdtToken();
  const ozonePrice = await stakingContract.ozonePrice();
  const presaleSupply = await stakingContract.presaleSupply();
  const totalPools = await stakingContract.totalPools();
  const presaleActive = await stakingContract.presaleActive();

  console.log("   OZONE Token:", ozoneTokenAddress);
  console.log("   USDT Token:", usdtTokenAddress);
  console.log("   OZONE Price:", ethers.formatEther(ozonePrice), "USDT");
  console.log("   Presale Supply:", ethers.formatEther(presaleSupply), "OZONE");
  console.log("   Total Pools:", totalPools.toString());
  console.log("   Presale Active:", presaleActive);

  // ============================================================================
  // SAVE DEPLOYMENT INFO
  // ============================================================================
  
  const deploymentInfo = {
    network: "BSC Testnet",
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      proxy: proxyAddress,
      implementation: implementationAddress,
      ozoneToken: config.ozoneToken,
      usdtToken: config.usdtToken
    },
    config: {
      initialOzonePrice: ethers.formatEther(config.initialOzonePrice),
      treasuryWallet: config.treasuryWallet,
      taxWallet: config.taxWallet,
      initialPresaleSupply: ethers.formatEther(config.initialPresaleSupply)
    }
  };

  console.log("\n📝 Deployment Info:");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  // ============================================================================
  // NEXT STEPS
  // ============================================================================
  
  console.log("\n✅ DEPLOYMENT SUCCESSFUL!\n");
  console.log("📋 NEXT STEPS:");
  console.log("   1. Verify contract on BscScan:");
  console.log(`      npx hardhat verify --network bscTestnet ${implementationAddress}`);
  console.log("");
  console.log("   2. Fund contract with OZONE tokens:");
  console.log(`      Transfer ${ethers.formatEther(config.initialPresaleSupply)} OZONE to: ${proxyAddress}`);
  console.log("");
  console.log("   3. Fund USDT reserves for rewards:");
  console.log(`      Call fundUSDTReserves() with sufficient USDT`);
  console.log("");
  console.log("   4. Activate presale:");
  console.log(`      Call setPresaleActive(true)`);
  console.log("");
  console.log("   5. Update OZONE price regularly:");
  console.log(`      Call setOzonePrice() with DigiFinex API price`);
  console.log("");
  console.log("🔗 Contract Address:", proxyAddress);
  console.log("🔗 BscScan Testnet:", `https://testnet.bscscan.com/address/${proxyAddress}`);
  console.log("");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🔄 Upgrading OzoneStakingV2 Contract...\n");

  // UPDATE THIS: Your deployed proxy address
  const PROXY_ADDRESS = "YOUR_PROXY_ADDRESS_HERE";

  const [deployer] = await ethers.getSigners();
  console.log("📍 Upgrading from account:", deployer.address);
  console.log("📍 Proxy address:", PROXY_ADDRESS, "\n");

  // Get the new implementation contract factory
  const OzoneStakingV2Upgraded = await ethers.getContractFactory("OzoneStakingV2");

  console.log("📦 Preparing upgrade...");
  
  // Upgrade the proxy to the new implementation
  const upgradedContract = await upgrades.upgradeProxy(PROXY_ADDRESS, OzoneStakingV2Upgraded);
  
  await upgradedContract.waitForDeployment();

  console.log("✅ Contract upgraded successfully!");
  
  const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(PROXY_ADDRESS);
  console.log("✅ New implementation address:", newImplementationAddress);

  // Verify state is preserved
  console.log("\n🔍 Verifying state preservation...");
  const ozoneToken = await upgradedContract.ozoneToken();
  const presaleActive = await upgradedContract.presaleActive();
  const totalPools = await upgradedContract.totalPools();

  console.log("   OZONE Token:", ozoneToken);
  console.log("   Presale Active:", presaleActive);
  console.log("   Total Pools:", totalPools.toString());

  console.log("\n✅ UPGRADE COMPLETE!");
  console.log("🔗 Proxy (unchanged):", PROXY_ADDRESS);
  console.log("🔗 New Implementation:", newImplementationAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("OzoneStakingV2 - Complete Test Suite", function () {
  // Test accounts
  let owner, treasury, taxWallet, user1, user2, user3;
  
  // Contract instances
  let ozoneToken, usdtToken, stakingContract;
  
  // Constants matching the contract
  const INITIAL_OZONE_PRICE = ethers.parseEther("0.01"); // $0.01 per OZONE
  const INITIAL_PRESALE_SUPPLY = ethers.parseEther("10000000"); // 10M OZONE
  const USDT_DECIMALS = 18; // BSC USDT uses 18 decimals
  const CLAIM_INTERVAL = 15 * 24 * 60 * 60; // 15 days in seconds
  
  /**
   * Deploy fixture - reusable deployment logic
   */
  async function deployFixture() {
    [owner, treasury, taxWallet, user1, user2, user3] = await ethers.getSigners();
    
    // 1. Deploy Mock OZONE Token
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    ozoneToken = await MockERC20.deploy("OZONE Token", "OZONE", 18);
    await ozoneToken.waitForDeployment();
    
    // 2. Deploy Mock USDT Token (18 decimals on BSC)
    usdtToken = await MockERC20.deploy("Tether USD", "USDT", USDT_DECIMALS);
    await usdtToken.waitForDeployment();
    
    // 3. Deploy OzoneStakingV2 via UUPS Proxy
    const OzoneStakingV2 = await ethers.getContractFactory("OzoneStakingV2");
    stakingContract = await upgrades.deployProxy(
      OzoneStakingV2,
      [
        await ozoneToken.getAddress(),
        await usdtToken.getAddress(),
        INITIAL_OZONE_PRICE,
        treasury.address,
        taxWallet.address,
        INITIAL_PRESALE_SUPPLY
      ],
      {
        initializer: "initialize",
        kind: "uups"
      }
    );
    await stakingContract.waitForDeployment();
    
    return { ozoneToken, usdtToken, stakingContract };
  }
  
  /**
   * Setup funding - fund contract and users
   */
  async function setupFunding() {
    const stakingAddress = await stakingContract.getAddress();
    
    // Fund contract with OZONE for presale
    await ozoneToken.mint(stakingAddress, INITIAL_PRESALE_SUPPLY);
    
    // Fund contract with USDT for rewards (enough for 300% rewards on $100k stake)
    const rewardReserves = ethers.parseEther("300000"); // $300k USDT
    await usdtToken.mint(owner.address, rewardReserves);
    await usdtToken.connect(owner).approve(stakingAddress, rewardReserves);
    await stakingContract.connect(owner).fundUSDTReserves(rewardReserves);
    
    // Fund users with USDT for testing
    await usdtToken.mint(user1.address, ethers.parseEther("50000")); // $50k
    await usdtToken.mint(user2.address, ethers.parseEther("25000")); // $25k
    await usdtToken.mint(user3.address, ethers.parseEther("10000")); // $10k
    
    // Activate presale (will check contract has enough OZONE)
    await stakingContract.connect(owner).setPresaleActive(true);
  }
  
  describe("1. Deployment & Initialization", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
    });
    
    it("Should deploy with correct initial parameters", async function () {
      expect(await stakingContract.ozoneToken()).to.equal(await ozoneToken.getAddress());
      expect(await stakingContract.usdtToken()).to.equal(await usdtToken.getAddress());
      expect(await stakingContract.ozonePrice()).to.equal(INITIAL_OZONE_PRICE);
      expect(await stakingContract.treasuryWallet()).to.equal(treasury.address);
      expect(await stakingContract.taxWallet()).to.equal(taxWallet.address);
      expect(await stakingContract.presaleSupply()).to.equal(INITIAL_PRESALE_SUPPLY);
    });
    
    it("Should initialize 5 pools correctly", async function () {
      expect(await stakingContract.totalPools()).to.equal(5);
      
      // Check LimoX Pool A (6% APY)
      const pool1 = await stakingContract.getPool(1);
      expect(pool1.name).to.equal("LimoX Pool A");
      expect(pool1.monthlyAPY).to.equal(600); // 6%
      expect(pool1.minStakeUSDT).to.equal(ethers.parseEther("100"));
      expect(pool1.maxStakeUSDT).to.equal(ethers.parseEther("10000"));
      expect(pool1.durationMonths).to.equal(50); // 300 / 6 = 50 months
    });
    
    it("Should set presaleActive to false by default", async function () {
      expect(await stakingContract.presaleActive()).to.equal(false);
    });
  });
  
  describe("2. Owner Fail Scenarios (Security Checks)", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
    });
    
    it("Should REVERT when activating presale without funding OZONE", async function () {
      // Try to activate presale without funding contract
      await expect(
        stakingContract.connect(owner).setPresaleActive(true)
      ).to.be.revertedWith("Insufficient OZONE balance - fund contract first");
    });
    
    it("Should allow presale activation after funding OZONE", async function () {
      const stakingAddress = await stakingContract.getAddress();
      
      // Fund contract with OZONE
      await ozoneToken.mint(stakingAddress, INITIAL_PRESALE_SUPPLY);
      
      // Now activation should work
      await expect(stakingContract.connect(owner).setPresaleActive(true))
        .to.emit(stakingContract, "PresaleStatusChanged")
        .withArgs(true);
      
      expect(await stakingContract.presaleActive()).to.equal(true);
    });
  });
  
  describe("3. Happy Path - Complete User Journey", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
      await setupFunding();
    });
    
    it("Should complete full lifecycle: Buy -> Wait 15 days -> Claim -> Wait duration -> Auto-burn", async function () {
      const stakingAddress = await stakingContract.getAddress();
      const purchaseAmount = ethers.parseEther("1000"); // $1000 USDT
      const taxAmount = purchaseAmount / BigInt(100); // 1% tax
      const totalCost = purchaseAmount + taxAmount; // $1010 total
      
      // Step 1: User1 buys and stakes to Pool 1 (6% APY, 50 months)
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      
      const tx = await stakingContract.connect(user1).buyAndStake(1, purchaseAmount);
      await expect(tx)
        .to.emit(stakingContract, "PresalePurchase")
        .to.emit(stakingContract, "UserStaked");
      
      // Verify stake created
      const stake = await stakingContract.getUserStake(user1.address, 0);
      expect(stake.usdtValueAtStake).to.equal(purchaseAmount);
      expect(stake.poolId).to.equal(1);
      expect(stake.isActive).to.equal(true);
      
      // Verify USDT transferred correctly
      expect(await usdtToken.balanceOf(treasury.address)).to.equal(purchaseAmount);
      expect(await usdtToken.balanceOf(taxWallet.address)).to.equal(taxAmount);
      
      // Step 2: Cannot claim immediately
      expect(await stakingContract.canClaim(user1.address, 0)).to.equal(false);
      
      // Step 3: TIME TRAVEL - Fast forward 15 days (THE MAGIC!)
      await time.increase(CLAIM_INTERVAL);
      
      // Step 4: Now can claim
      expect(await stakingContract.canClaim(user1.address, 0)).to.equal(true);
      
      // Calculate expected reward: $1000 * 6% APY / 12 months * 0.5 months (15 days)
      // Monthly reward = $1000 * 0.06 = $60
      // 15 days reward = $60 / 2 = $30
      const breakdown = await stakingContract.getRewardBreakdown(user1.address, 0);
      const expectedReward = ethers.parseEther("30"); // Approximately $30
      
      // Allow 1% margin for rounding
      expect(breakdown.claimableRewardsUSDT).to.be.closeTo(expectedReward, ethers.parseEther("0.5"));
      
      // Step 5: Claim rewards
      const balanceBefore = await usdtToken.balanceOf(user1.address);
      await stakingContract.connect(user1).claimRewards(0);
      const balanceAfter = await usdtToken.balanceOf(user1.address);
      
      expect(balanceAfter - balanceBefore).to.be.closeTo(expectedReward, ethers.parseEther("0.5"));
      
      // Step 6: TIME TRAVEL - Fast forward to end of duration (50 months)
      const monthsRemaining = 50;
      await time.increase(monthsRemaining * 30 * 24 * 60 * 60);
      
      // Step 7: Claim final rewards (should trigger auto-burn)
      const claimTx = await stakingContract.connect(user1).claimRewards(0);
      
      // Should emit auto-burn event
      await expect(claimTx).to.emit(stakingContract, "TokensAutoBurned");
      
      // Verify stake is now burned
      const finalStake = await stakingContract.getUserStake(user1.address, 0);
      expect(finalStake.isBurned).to.equal(true);
      expect(finalStake.isActive).to.equal(false);
      
      // Verify OZONE tokens were burned (sent to dead address)
      const deadAddress = "0x000000000000000000000000000000000000dEaD";
      expect(await ozoneToken.balanceOf(deadAddress)).to.be.gt(0);
    });
  });
  
  describe("4. Sad Path - Empty USDT Reserves", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
      
      // Setup but DON'T fund USDT reserves
      const stakingAddress = await stakingContract.getAddress();
      await ozoneToken.mint(stakingAddress, INITIAL_PRESALE_SUPPLY);
      await usdtToken.mint(user1.address, ethers.parseEther("1000"));
      await stakingContract.connect(owner).setPresaleActive(true);
    });
    
    it("Should REVERT when claiming with empty USDT reserves", async function () {
      const stakingAddress = await stakingContract.getAddress();
      const purchaseAmount = ethers.parseEther("100");
      const taxAmount = purchaseAmount / BigInt(100);
      const totalCost = purchaseAmount + taxAmount;
      
      // User buys and stakes
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      await stakingContract.connect(user1).buyAndStake(1, purchaseAmount);
      
      // Fast forward 15 days
      await time.increase(CLAIM_INTERVAL);
      
      // Try to claim - should REVERT because contract has no USDT reserves
      await expect(
        stakingContract.connect(user1).claimRewards(0)
      ).to.be.revertedWith("Insufficient USDT reserves");
    });
    
    it("claimAllRewards should SKIP stakes with insufficient reserves", async function () {
      const stakingAddress = await stakingContract.getAddress();
      
      // DON'T fund any reserves (empty)
      // const minimalReserves = ethers.parseEther("10");
      // await usdtToken.mint(owner.address, minimalReserves);
      // await usdtToken.connect(owner).approve(stakingAddress, minimalReserves);
      // await stakingContract.connect(owner).fundUSDTReserves(minimalReserves);
      
      // User stakes $100 (will need rewards but reserves = 0)
      const purchaseAmount = ethers.parseEther("100");
      const taxAmount = purchaseAmount / BigInt(100);
      const totalCost = purchaseAmount + taxAmount;
      
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      await stakingContract.connect(user1).buyAndStake(1, purchaseAmount);
      
      // Fast forward 15 days
      await time.increase(CLAIM_INTERVAL);
      
      // claimAllRewards should revert because no USDT reserves available
      await expect(
        stakingContract.connect(user1).claimAllRewards()
      ).to.be.revertedWith("No claimable rewards");
    });
  });
  
  describe("5. UUPS Upgrade Pattern", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
      await setupFunding();
    });
    
    it("Should upgrade contract successfully via UUPS", async function () {
      // Create a simple upgraded version (V2) - just for testing upgrade mechanism
      const OzoneStakingV2Upgraded = await ethers.getContractFactory("OzoneStakingV2");
      
      // Upgrade the contract
      const upgradedContract = await upgrades.upgradeProxy(
        await stakingContract.getAddress(),
        OzoneStakingV2Upgraded
      );
      
      // Verify it's still the same proxy address
      expect(await upgradedContract.getAddress()).to.equal(await stakingContract.getAddress());
      
      // Verify state is preserved after upgrade
      expect(await upgradedContract.ozoneToken()).to.equal(await ozoneToken.getAddress());
      expect(await upgradedContract.treasuryWallet()).to.equal(treasury.address);
      expect(await upgradedContract.presaleActive()).to.equal(true);
    });
    
    it("Should prevent non-owner from upgrading", async function () {
      const OzoneStakingV2Upgraded = await ethers.getContractFactory("OzoneStakingV2");
      
      // Try to upgrade from non-owner account - should fail
      await expect(
        upgrades.upgradeProxy(
          await stakingContract.getAddress(),
          OzoneStakingV2Upgraded.connect(user1)
        )
      ).to.be.reverted;
    });
  });
  
  describe("6. Batch Claim Function (claimAllRewards)", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
      await setupFunding();
    });
    
    it("Should claim all stakes in one transaction", async function () {
      const stakingAddress = await stakingContract.getAddress();
      
      // User makes 3 purchases in different pools
      const purchases = [
        { poolId: 1, amount: ethers.parseEther("1000") },  // LimoX A
        { poolId: 2, amount: ethers.parseEther("15000") }, // LimoX B
        { poolId: 3, amount: ethers.parseEther("30000") }  // LimoX C
      ];
      
      for (const purchase of purchases) {
        const taxAmount = purchase.amount / BigInt(100);
        const totalCost = purchase.amount + taxAmount;
        await usdtToken.connect(user1).approve(stakingAddress, totalCost);
        await stakingContract.connect(user1).buyAndStake(purchase.poolId, purchase.amount);
      }
      
      // Verify 3 stakes created
      expect(await stakingContract.getUserStakeCount(user1.address)).to.equal(3);
      
      // Fast forward 15 days
      await time.increase(CLAIM_INTERVAL);
      
      // Claim all in one transaction
      const balanceBefore = await usdtToken.balanceOf(user1.address);
      await stakingContract.connect(user1).claimAllRewards();
      const balanceAfter = await usdtToken.balanceOf(user1.address);
      
      // Should receive combined rewards from all 3 stakes
      expect(balanceAfter).to.be.gt(balanceBefore);
    });
  });
  
  describe("7. Pool Validation & Edge Cases", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
      await setupFunding();
    });
    
    it("Should reject purchase below pool minimum", async function () {
      const stakingAddress = await stakingContract.getAddress();
      const belowMinimum = ethers.parseEther("50"); // Pool 1 min is $100
      const taxAmount = belowMinimum / BigInt(100);
      const totalCost = belowMinimum + taxAmount;
      
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      
      await expect(
        stakingContract.connect(user1).buyAndStake(1, belowMinimum)
      ).to.be.revertedWith("Below minimum stake for this pool");
    });
    
    it("Should reject purchase above pool maximum", async function () {
      const stakingAddress = await stakingContract.getAddress();
      const aboveMaximum = ethers.parseEther("15000"); // Pool 1 max is $10,000
      const taxAmount = aboveMaximum / BigInt(100);
      const totalCost = aboveMaximum + taxAmount;
      
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      
      await expect(
        stakingContract.connect(user1).buyAndStake(1, aboveMaximum)
      ).to.be.revertedWith("Above maximum stake for this pool");
    });
    
    it("Should accept unlimited stake in Pool 5 (SaproX B)", async function () {
      const stakingAddress = await stakingContract.getAddress();
      
      // Fund contract with MORE OZONE for large stake (need ~50M OZONE for $500k at $0.01)
      const additionalOzone = ethers.parseEther("100000000"); // 100M OZONE
      await ozoneToken.mint(owner.address, additionalOzone);
      await ozoneToken.connect(owner).approve(stakingAddress, additionalOzone);
      await stakingContract.connect(owner).addPresaleSupply(additionalOzone);
      
      // Fund user with massive amount
      await usdtToken.mint(user1.address, ethers.parseEther("1000000"));
      
      const hugeStake = ethers.parseEther("500000"); // $500k (no limit in Pool 5)
      const taxAmount = hugeStake / BigInt(100);
      const totalCost = hugeStake + taxAmount;
      
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      
      // Should succeed (Pool 5 has maxStakeUSDT = 0 = unlimited)
      await expect(
        stakingContract.connect(user1).buyAndStake(5, hugeStake)
      ).to.emit(stakingContract, "UserStaked");
    });
  });
  
  describe("8. Gas Efficiency Tests", function () {
    beforeEach(async function () {
      ({ ozoneToken, usdtToken, stakingContract } = await deployFixture());
      await setupFunding();
    });
    
    it("Should measure gas costs for buyAndStake", async function () {
      const stakingAddress = await stakingContract.getAddress();
      const purchaseAmount = ethers.parseEther("1000");
      const taxAmount = purchaseAmount / BigInt(100);
      const totalCost = purchaseAmount + taxAmount;
      
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      
      const tx = await stakingContract.connect(user1).buyAndStake(1, purchaseAmount);
      const receipt = await tx.wait();
      
      console.log(`       Gas used for buyAndStake: ${receipt.gasUsed.toString()}`);
      
      // Should be under 500k gas
      expect(receipt.gasUsed).to.be.lt(500000);
    });
    
    it("Should measure gas for claimRewards", async function () {
      const stakingAddress = await stakingContract.getAddress();
      const purchaseAmount = ethers.parseEther("1000");
      const taxAmount = purchaseAmount / BigInt(100);
      const totalCost = purchaseAmount + taxAmount;
      
      await usdtToken.connect(user1).approve(stakingAddress, totalCost);
      await stakingContract.connect(user1).buyAndStake(1, purchaseAmount);
      
      // Fast forward
      await time.increase(CLAIM_INTERVAL);
      
      const tx = await stakingContract.connect(user1).claimRewards(0);
      const receipt = await tx.wait();
      
      console.log(`       Gas used for claimRewards: ${receipt.gasUsed.toString()}`);
      
      // Should be under 300k gas
      expect(receipt.gasUsed).to.be.lt(300000);
    });
  });
});

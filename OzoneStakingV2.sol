// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 ██████╗ ███████╗ ██████╗ ███╗   ██╗███████╗
██╔═══██╗╚══███╔╝██╔═══██╗████╗  ██║██╔════╝
██║   ██║  ███╔╝ ██║   ██║██╔██╗ ██║█████╗  
██║   ██║ ███╔╝  ██║   ██║██║╚██╗██║██╔══╝  
╚██████╔╝███████╗╚██████╔╝██║ ╚████║███████╗
 ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    🏭 OZONE STAKING V2 - Integrated Presale & Staking Platform
    
    ════════════════════════════════════════════════════════════════════
    │  🛒 Buy & Stake: One-Click Purchase + Auto-Stake               │
    │  🎯 Manual Pool Selection: Choose Your Tier (LimoX/SaproX)    │
    │  💰 LimoX Pools: 6-8% Monthly APY                              │
    │  💎 SaproX Pools: 9-10% Monthly APY                            │
    │  ⏰ Claim Every 15 Days (Time-Based)                            │
    │  🔥 Duration-Based Auto-Burn: (300% ÷ APY) Months             │
    │  🔄 UUPS Upgradeable for Future Enhancements                   │
    ════════════════════════════════════════════════════════════════════
    
    💡 Buy OZONE with USDT → Auto-stake to selected pool → Earn USDT daily
       Duration locked: 6% APY = 50 months, 10% APY = 30 months
*/

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface untuk OZONE Token PoR integration
interface IOZONEToken {
    function getProofOfReserves() external view returns (uint256 treasuryBalance, uint256 monthlyProfit, uint256 distributedRewards, uint256 availableForRewards);
}

/**
 * @title OzoneStakingV2 - Integrated Presale & Staking Platform
 * @dev UUPS Upgradeable system with presale + manual pool selection + time-based claims
 * @notice Gas-optimized single contract for BSC Mainnet (v2.0 - Upgradeable)
 * @author OZONE Team - December 2025
 */
contract OzoneStakingV2 is 
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable 
{
    
    // =============================================================================
    // ENUMS & STRUCTS
    // =============================================================================
    
    /**
     * @dev Pool structure dengan USDT-only rewards
     */
    struct Pool {
        string name;                    // Pool name (e.g., "LimoX Pool A")
        uint256 monthlyAPY;            // Monthly APY dalam basis points (600 = 6%)
        uint256 minStakeUSDT;          // Minimum USDT value to qualify
        uint256 maxStakeUSDT;          // Maximum USDT value (0 = unlimited)
        uint256 claimInterval;         // Claim interval dalam seconds (15 days)
        uint256 maxRewardPercent;      // Max reward percentage (30000 = 300%)
        bool enableAutoBurn;           // Auto burn when reaching max reward
        uint256 totalStaked;           // Total OZONE staked di pool ini
        uint256 totalClaimed;          // Total rewards claimed dari pool ini
        bool isActive;                 // Pool active status
        uint256 createdAt;             // Pool creation timestamp
        uint256 durationMonths;        // Duration in months (300 / APY)
    }
    
    /**
     * @dev UserStake structure dengan dual reward tracking
     */
    struct UserStake {
        uint256 amount;                // Amount received by contract (after tax if any)
        uint256 originalAmount;        // Original amount staked - untuk reward calculation
        uint256 usdtValueAtStake;      // USDT value saat stake (for tier locking)
        uint256 poolId;                // Pool ID (tier locked)
        uint256 lockedAPY;             // APY locked at stake time
        uint256 startTime;             // Stake start time
        uint256 lastClaimTime;         // Last claim timestamp
        uint256 totalClaimedReward;    // Total rewards claimed (USDT equivalent)
        uint256 nextClaimTime;         // Next available claim time
        bool isActive;                 // Stake active status
        bool isBurned;                 // Auto-burned status
        uint256 endTime;               // Expected end time (duration-based)
        bool isFromPresale;            // Whether stake is from presale
    }
    
    // =============================================================================
    // STATE VARIABLES
    // =============================================================================
    
    // Token References
    IERC20 public ozoneToken;
    IERC20 public usdtToken;
    IOZONEToken public ozoneContract;
    
    // Pool Management
    mapping(uint256 => Pool) public pools;
    mapping(address => UserStake[]) public userStakes;
    uint256 public totalPools;
    uint256 public nextPoolId;
    
    // Reserve Management
    uint256 public stakingUSDTReserves;      // USDT reserves untuk staking rewards
    uint256 public totalStakingDistributed;  // Total USDT distributed
    uint256 public totalTokensBurned;        // Total OZONE burned
    uint256 public activeStakeCount;         // Active stakes count
    
    // Presale Management
    uint256 public presaleSupply;            // Available OZONE for presale
    uint256 public totalPresaleSold;         // Total OZONE sold via presale
    address public treasuryWallet;           // Treasury wallet for USDT
    address public taxWallet;                // Tax wallet for platform fees (1% USDT)
    bool public presaleActive;               // Presale active status
    
    // Constants - Production Configuration
    uint256 public constant MAX_REWARD_PERCENTAGE = 30000; // 300% maximum
    uint256 public constant CLAIM_INTERVAL = 15 days;      // 15 days claim interval
    uint256 public constant MONTH_DURATION = 30 days;      // 30 days = 1 month
    uint256 public constant PURCHASE_TAX_RATE = 100;       // 1% platform fee (100 basis points)
    uint256 public constant BASIS_POINTS = 10000;          // 100% = 10000 basis points
    
    // Price Management
    uint256 public ozonePrice; // OZONE price in USDT (18 decimals)
    
    // Contract Version
    string public constant VERSION = "2.0.0-Integrated"; // Single contract with presale
    
    // =============================================================================
    // EVENTS
    // =============================================================================
    
    // Staking Events
    event UserStaked(address indexed user, uint256 indexed poolId, uint256 ozoneAmount, uint256 usdtValue, uint256 stakeIndex, bool fromPresale);
    event UserUnstaked(address indexed user, uint256 indexed stakeIndex, uint256 amount);
    
    // Reward Events
    event RewardClaimed(address indexed user, uint256 indexed stakeIndex, uint256 usdtAmount, uint256 totalClaimed);
    event TokensAutoBurned(address indexed user, uint256 indexed stakeIndex, uint256 burnedAmount, uint256 totalRewardsClaimed);
    
    // Presale Events
    event PresalePurchase(address indexed buyer, uint256 indexed poolId, uint256 usdtPaid, uint256 ozoneReceived, uint256 stakeIndex);
    event PresaleSupplyAdded(uint256 amount, uint256 newTotal);
    event TreasuryWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event TaxWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event PurchaseTaxCollected(address indexed buyer, uint256 taxAmount);
    event PresaleStatusChanged(bool active);
    
    // Pool Events
    event PoolCreated(uint256 indexed poolId, string name, uint256 monthlyAPY, uint256 minUSDT, uint256 maxUSDT);
    event PoolUpdated(uint256 indexed poolId, string name, uint256 monthlyAPY);
    event PoolDeactivated(uint256 indexed poolId, string reason);
    
    // Reserve Events
    event USDTReservesFunded(uint256 amount);
    event USDTReservesWithdrawn(uint256 amount);
    
    // Price Events
    event OzonePriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    
    // Upgrade Events
    event ContractUpgraded(address indexed newImplementation, uint256 timestamp);
    
    // =============================================================================
    // CONSTRUCTOR & INITIALIZER
    // =============================================================================
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @dev Initialize the contract (replaces constructor for upgradeable contracts)
     */
    function initialize(
        address _ozoneToken,
        address _usdtToken,
        address _ozoneContract,
        uint256 _initialOzonePrice,
        address _treasuryWallet,
        address _taxWallet,
        uint256 _initialPresaleSupply
    ) public initializer {
        require(_ozoneToken != address(0), "Invalid OZONE token");
        require(_usdtToken != address(0), "Invalid USDT token");
        require(_ozoneContract != address(0), "Invalid OZONE contract");
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        require(_taxWallet != address(0), "Invalid tax wallet");
        require(_initialOzonePrice > 0, "Invalid price");
        
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        ozoneToken = IERC20(_ozoneToken);
        usdtToken = IERC20(_usdtToken);
        ozoneContract = IOZONEToken(_ozoneContract);
        ozonePrice = _initialOzonePrice;
        treasuryWallet = _treasuryWallet;
        taxWallet = _taxWallet;
        presaleSupply = _initialPresaleSupply;
        presaleActive = true;
        
        nextPoolId = 1;
        totalPools = 0;
        
        // Initialize 5 pools (LimoX A/B/C, SaproX A/B)
        _initializePools();
    }
    
    /**
     * @dev Initialize default 5-tier pool system (same as original)
     */
    function _initializePools() private {
        // LimoX Pool A: 100-10,000 OZONE (6% monthly APY) = 50 months duration
        _createPool(
            "LimoX Pool A",
            600,                        // 6% APY
            100 * 10**18,              // Min 100 OZONE
            10000 * 10**18,            // Max 10,000 OZONE
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true                        // enableAutoBurn
        );
        
        // LimoX Pool B: 10,001-25,000 OZONE (7% monthly APY) = ~43 months duration
        _createPool(
            "LimoX Pool B",
            700,                        // 7% APY
            10001 * 10**18,            // Min 10,001 OZONE
            25000 * 10**18,            // Max 25,000 OZONE
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true
        );
        
        // LimoX Pool C: 25,001-50,000 OZONE (8% monthly APY) = 37.5 months duration
        _createPool(
            "LimoX Pool C",
            800,                        // 8% APY
            25001 * 10**18,            // Min 25,001 OZONE
            50000 * 10**18,            // Max 50,000 OZONE
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true
        );
        
        // SaproX Pool A: 50,001-100,000 OZONE (9% monthly APY) = ~33 months duration
        _createPool(
            "SaproX Pool A",
            900,                        // 9% APY
            50001 * 10**18,            // Min 50,001 OZONE
            100000 * 10**18,           // Max 100,000 OZONE
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true
        );
        
        // SaproX Pool B: 100,001+ OZONE (10% monthly APY) = 30 months duration
        _createPool(
            "SaproX Pool B",
            1000,                       // 10% APY
            100001 * 10**18,           // Min 100,001 OZONE
            0,                          // No max (unlimited)
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true
        );
    }
    
    // =============================================================================
    // POOL MANAGEMENT
    // =============================================================================
    
    /**
     * @dev Internal function to create pool
     */
    function _createPool(
        string memory _name,
        uint256 _monthlyAPY,
        uint256 _minStake,
        uint256 _maxStake,
        uint256 _claimInterval,
        uint256 _maxRewardPercent,
        bool _enableAutoBurn
    ) private {
        uint256 poolId = nextPoolId;
        
        // Calculate duration in months: 300 / APY
        uint256 durationMonths = (MAX_REWARD_PERCENTAGE * 100) / _monthlyAPY;
        
        pools[poolId] = Pool({
            name: _name,
            monthlyAPY: _monthlyAPY,
            minStakeUSDT: _minStake,
            maxStakeUSDT: _maxStake,
            claimInterval: _claimInterval,
            maxRewardPercent: _maxRewardPercent,
            enableAutoBurn: _enableAutoBurn,
            totalStaked: 0,
            totalClaimed: 0,
            isActive: true,
            createdAt: block.timestamp,
            durationMonths: durationMonths
        });
        
        nextPoolId++;
        totalPools++;
        
        emit PoolCreated(poolId, _name, _monthlyAPY, _minStake, _maxStake);
    }
    
    /**
     * @dev Update existing pool (only owner)
     */
    function updatePool(
        uint256 _poolId,
        string memory _name,
        uint256 _monthlyAPY,
        uint256 _minStake,
        uint256 _maxStake
    ) external onlyOwner {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        require(_monthlyAPY > 0 && _monthlyAPY <= 10000, "Invalid APY");
        
        Pool storage pool = pools[_poolId];
        pool.name = _name;
        pool.monthlyAPY = _monthlyAPY;
        pool.minStakeUSDT = _minStake;
        pool.maxStakeUSDT = _maxStake;
        pool.durationMonths = (MAX_REWARD_PERCENTAGE * 100) / _monthlyAPY;
        
        emit PoolUpdated(_poolId, _name, _monthlyAPY);
    }
    
    /**
     * @dev Deactivate pool
     */
    function deactivatePool(uint256 _poolId, string memory _reason) external onlyOwner {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        pools[_poolId].isActive = false;
        emit PoolDeactivated(_poolId, _reason);
    }
    
    // =============================================================================
    // PRESALE & STAKING FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Buy OZONE with USDT and auto-stake to selected pool (ONE-CLICK)
     * @param _poolId Pool ID yang dipilih user (manual selection)
     * @param _usdtAmount Amount of USDT to spend
     */
    function buyAndStake(uint256 _poolId, uint256 _usdtAmount) external nonReentrant whenNotPaused {
        require(presaleActive, "Presale not active");
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        require(_usdtAmount > 0, "Amount must be greater than 0");
        
        Pool memory pool = pools[_poolId];
        require(pool.isActive, "Pool is not active");
        
        // Calculate 1% platform fee
        uint256 taxAmount = (_usdtAmount * PURCHASE_TAX_RATE) / BASIS_POINTS; // 1% tax
        uint256 totalCost = _usdtAmount + taxAmount; // User pays base price + 1% fee
        
        // Check user's USDT balance and allowance for total cost
        require(usdtToken.balanceOf(msg.sender) >= totalCost, "Insufficient USDT balance");
        require(usdtToken.allowance(msg.sender, address(this)) >= totalCost, "Insufficient USDT allowance");
        
        // Calculate OZONE amount to receive (based on base price, not including tax)
        uint256 ozoneAmount = (_usdtAmount * 10**18) / ozonePrice;
        require(ozoneAmount > 0, "Invalid OZONE amount");
        
        // Check presale supply
        require(ozoneAmount <= presaleSupply, "Insufficient presale supply");
        
        // Validate pool min/max (dalam OZONE tokens)
        require(ozoneAmount >= pool.minStakeUSDT, "Below minimum stake for this pool");
        if (pool.maxStakeUSDT > 0) {
            require(ozoneAmount <= pool.maxStakeUSDT, "Above maximum stake for this pool");
        }
        
        // Transfer USDT: base price to treasury, tax to tax wallet
        require(usdtToken.transferFrom(msg.sender, treasuryWallet, _usdtAmount), "Base USDT transfer failed");
        require(usdtToken.transferFrom(msg.sender, taxWallet, taxAmount), "Tax USDT transfer failed");
        
        // Update presale stats
        presaleSupply -= ozoneAmount;
        totalPresaleSold += ozoneAmount;
        
        // Calculate USDT value at current price for staking record (base price only, excluding tax)
        uint256 usdtValue = _usdtAmount;
        
        // Create stake entry (OZONE stays in contract)
        // For presale, no OZONE transfer tax, so amount = originalAmount
        _createStakeEntry(msg.sender, _poolId, ozoneAmount, ozoneAmount, usdtValue, pool.monthlyAPY, true);
        
        uint256 stakeIndex = userStakes[msg.sender].length - 1;
        
        emit PresalePurchase(msg.sender, _poolId, _usdtAmount, ozoneAmount, stakeIndex);
        emit PurchaseTaxCollected(msg.sender, taxAmount);
        emit UserStaked(msg.sender, _poolId, ozoneAmount, usdtValue, stakeIndex, true);
    }
    
    /**
     * @dev Stake OZONE tokens ke pool tertentu (manual selection by existing OZONE holders)
     * @notice OZONE token has 1% transfer tax - contract receives 99%, but rewards calculated on 100%
     */
    function stake(uint256 _poolId, uint256 _amount) external nonReentrant whenNotPaused {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        require(_amount > 0, "Amount must be greater than 0");
        
        Pool memory pool = pools[_poolId];
        require(pool.isActive, "Pool is not active");
        
        // Validate pool min/max (dalam OZONE tokens - based on original amount)
        require(_amount >= pool.minStakeUSDT, "Below minimum stake for this pool");
        if (pool.maxStakeUSDT > 0) {
            require(_amount <= pool.maxStakeUSDT, "Above maximum stake for this pool");
        }
        
        // Calculate after-tax amount (OZONE has 1% transfer tax)
        // Contract will receive 99%, but we track the original 100% for reward calculation
        uint256 afterTaxAmount = (_amount * 99) / 100;
        
        // Transfer OZONE from user (user sends _amount, contract receives afterTaxAmount due to 1% tax)
        require(ozoneToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        // Calculate USDT value berdasarkan original amount (before tax) at current OZONE price
        // This ensures rewards are calculated fairly on the full amount user intended to stake
        uint256 usdtValue = (_amount * ozonePrice) / 10**18;
        
        // Create stake entry:
        // - amount: afterTaxAmount (what contract actually received - 99%)
        // - originalAmount: _amount (what user sent - 100%, used for reward calculation)
        _createStakeEntry(msg.sender, _poolId, afterTaxAmount, _amount, usdtValue, pool.monthlyAPY, false);
        
        emit UserStaked(msg.sender, _poolId, _amount, usdtValue, userStakes[msg.sender].length - 1, false);
    }
    
    /**
     * @dev Internal function to create stake entry
     */
    function _createStakeEntry(
        address _user,
        uint256 _poolId,
        uint256 _amount,
        uint256 _originalAmount,
        uint256 _usdtValue,
        uint256 _lockedAPY,
        bool _fromPresale
    ) private {
        // Calculate expected end time based on duration
        Pool memory pool = pools[_poolId];
        uint256 durationSeconds = pool.durationMonths * MONTH_DURATION;
        uint256 endTime = block.timestamp + durationSeconds;
        
        userStakes[_user].push(UserStake({
            amount: _amount,
            originalAmount: _originalAmount,
            usdtValueAtStake: _usdtValue,
            poolId: _poolId,
            lockedAPY: _lockedAPY,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            totalClaimedReward: 0,
            nextClaimTime: block.timestamp + CLAIM_INTERVAL,
            isActive: true,
            isBurned: false,
            endTime: endTime,
            isFromPresale: _fromPresale
        }));
        
        pools[_poolId].totalStaked += _amount;
        activeStakeCount++;
    }
    
    // =============================================================================
    // REWARD CALCULATION
    // =============================================================================
    
    /**
     * @dev Calculate available USDT rewards untuk stake tertentu
     * @notice Rewards calculated daily based on USDT value at stake (fixed, tidak terpengaruh harga OZONE)
     */
    function calculateAvailableRewards(address _user, uint256 _stakeIndex) 
        public view returns (uint256 claimableRewardsUSDT, bool shouldAutoBurn) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        if (!userStake.isActive || userStake.isBurned) return (0, false);
        
        // Calculate time elapsed in days
        uint256 timeElapsed = block.timestamp - userStake.lastClaimTime;
        uint256 daysElapsed = timeElapsed / 1 days;
        
        if (daysElapsed == 0) return (0, false);
        
        // Calculate daily reward directly from USDT value at stake
        // Daily reward USDT = (usdtValueAtStake * lockedAPY) / 10000 / 30
        // Contoh: $1000 USDT × 6% APY = $60/bulan = $2/hari
        uint256 dailyRewardUSDT = (userStake.usdtValueAtStake * userStake.lockedAPY) / 10000 / 30;
        uint256 totalRewardUSDT = dailyRewardUSDT * daysElapsed;
        
        // Check maximum reward (300% of USDT value at stake)
        uint256 maxRewardUSDT = (userStake.usdtValueAtStake * MAX_REWARD_PERCENTAGE) / 10000;
        uint256 remainingRewardUSDT = maxRewardUSDT - userStake.totalClaimedReward;
        
        if (totalRewardUSDT > remainingRewardUSDT) {
            totalRewardUSDT = remainingRewardUSDT;
        }
        
        // Check if duration has passed (auto-burn condition)
        shouldAutoBurn = false;
        Pool memory pool = pools[userStake.poolId];
        if (pool.enableAutoBurn && block.timestamp >= userStake.endTime) {
            shouldAutoBurn = true;
        }
        
        return (totalRewardUSDT, shouldAutoBurn);
    }
    
    // =============================================================================
    // CLAIM FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Check if user can claim rewards (TIME-BASED: Every 15 days)
     */
    function canClaim(address _user, uint256 _stakeIndex) public view returns (bool) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        if (!userStake.isActive || userStake.isBurned) return false;
        
        // Check if 15 days have passed since last claim
        return block.timestamp >= userStake.nextClaimTime;
    }
    
    /**
     * @dev Claim USDT rewards
     */
    function claimRewards(uint256 _stakeIndex) external nonReentrant whenNotPaused {
        require(_stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        require(canClaim(msg.sender, _stakeIndex), "Cannot claim yet - must wait 15 days");
        
        UserStake storage userStake = userStakes[msg.sender][_stakeIndex];
        Pool memory pool = pools[userStake.poolId];
        
        (uint256 usdtRewards, bool shouldAutoBurn) = calculateAvailableRewards(msg.sender, _stakeIndex);
        require(usdtRewards > 0, "No rewards available");
        
        // Validate reserves
        require(usdtRewards <= stakingUSDTReserves, "Insufficient USDT reserves");
        
        // Update stake data
        userStake.lastClaimTime = block.timestamp;
        userStake.totalClaimedReward += usdtRewards;
        userStake.nextClaimTime = block.timestamp + pool.claimInterval;
        
        // Transfer USDT rewards
        stakingUSDTReserves -= usdtRewards;
        totalStakingDistributed += usdtRewards;
        require(usdtToken.transfer(msg.sender, usdtRewards), "USDT transfer failed");
        
        // Update pool stats
        pools[userStake.poolId].totalClaimed += usdtRewards;
        
        emit RewardClaimed(msg.sender, _stakeIndex, usdtRewards, userStake.totalClaimedReward);
        
        // Auto-burn if duration has passed
        if (shouldAutoBurn && pool.enableAutoBurn) {
            _autoBurnTokens(_stakeIndex);
        }
    }
    
    // =============================================================================
    // AUTO BURN & UNSTAKE
    // =============================================================================
    
    /**
     * @dev Auto burn tokens when reaching 300% rewards
     */
    function _autoBurnTokens(uint256 _stakeIndex) private {
        UserStake storage userStake = userStakes[msg.sender][_stakeIndex];
        require(userStake.isActive && !userStake.isBurned, "Invalid stake for burning");
        
        uint256 burnAmount = userStake.amount;
        
        // Mark as burned and inactive
        userStake.isBurned = true;
        userStake.isActive = false;
        
        // Update stats
        pools[userStake.poolId].totalStaked -= burnAmount;
        totalTokensBurned += burnAmount;
        activeStakeCount--;
        
        // Burn tokens (transfer to dead address)
        require(ozoneToken.transfer(address(0x000000000000000000000000000000000000dEaD), burnAmount), 
                "Burn failed");
        
        emit TokensAutoBurned(msg.sender, _stakeIndex, burnAmount, userStake.totalClaimedReward);
    }
    
    /**
     * @dev Manual unstake before reaching 300% (optional feature, can be disabled)
     * @notice This function allows early exit but may have penalties
     */
    function unstake(uint256 _stakeIndex) external nonReentrant whenNotPaused {
        require(_stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        
        UserStake storage userStake = userStakes[msg.sender][_stakeIndex];
        require(userStake.isActive && !userStake.isBurned, "Stake is not active");
        
        uint256 amountToReturn = userStake.amount;
        
        // Update state
        userStake.isActive = false;
        pools[userStake.poolId].totalStaked -= userStake.amount;
        activeStakeCount--;
        
        // Transfer OZONE back to user
        require(ozoneToken.transfer(msg.sender, amountToReturn), "Transfer failed");
        
        emit UserUnstaked(msg.sender, _stakeIndex, amountToReturn);
    }
    
    // =============================================================================
    // ADMIN FUNCTIONS - RESERVES
    // =============================================================================
    
    /**
     * @dev Fund USDT reserves untuk staking rewards
     */
    function fundUSDTReserves(uint256 _amount) external onlyOwner {
        require(usdtToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        stakingUSDTReserves += _amount;
        emit USDTReservesFunded(_amount);
    }
    
    /**
     * @dev Withdraw USDT reserves (emergency only)
     */
    function withdrawUSDTReserves(uint256 _amount) external onlyOwner {
        require(_amount <= stakingUSDTReserves, "Insufficient reserves");
        stakingUSDTReserves -= _amount;
        require(usdtToken.transfer(owner(), _amount), "Transfer failed");
        emit USDTReservesWithdrawn(_amount);
    }
    
    // =============================================================================
    // ADMIN FUNCTIONS - PRESALE
    // =============================================================================
    
    /**
     * @dev Add OZONE to presale supply
     */
    function addPresaleSupply(uint256 _amount) external onlyOwner {
        require(ozoneToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        presaleSupply += _amount;
        emit PresaleSupplyAdded(_amount, presaleSupply);
    }
    
    /**
     * @dev Set treasury wallet
     */
    function setTreasuryWallet(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid address");
        address oldTreasury = treasuryWallet;
        treasuryWallet = _newTreasury;
        emit TreasuryWalletUpdated(oldTreasury, _newTreasury);
    }
    
    /**
     * @dev Update tax wallet address (for 1% USDT platform fees)
     */
    function setTaxWallet(address _newTaxWallet) external onlyOwner {
        require(_newTaxWallet != address(0), "Invalid address");
        address oldTaxWallet = taxWallet;
        taxWallet = _newTaxWallet;
        emit TaxWalletUpdated(oldTaxWallet, _newTaxWallet);
    }
    
    /**
     * @dev Toggle presale active status
     */
    function setPresaleActive(bool _active) external onlyOwner {
        presaleActive = _active;
        emit PresaleStatusChanged(_active);
    }
    
    // =============================================================================
    // ADMIN FUNCTIONS - GENERAL
    // =============================================================================
    
    /**
     * @dev Set OZONE price (manual update, will be replaced with oracle later)
     */
    function setOzonePrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Invalid price");
        uint256 oldPrice = ozonePrice;
        ozonePrice = _price;
        emit OzonePriceUpdated(oldPrice, _price, block.timestamp);
    }
    
    /**
     * @dev Pause contract (emergency)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Get pool information
     */
    function getPool(uint256 _poolId) external view returns (Pool memory) {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        return pools[_poolId];
    }
    
    /**
     * @dev Get all pools
     */
    function getAllPools() external view returns (Pool[] memory) {
        Pool[] memory allPools = new Pool[](totalPools);
        for (uint256 i = 1; i < nextPoolId; i++) {
            allPools[i - 1] = pools[i];
        }
        return allPools;
    }
    
    /**
     * @dev Get user stake information
     */
    function getUserStake(address _user, uint256 _stakeIndex) external view returns (UserStake memory) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        return userStakes[_user][_stakeIndex];
    }
    
    /**
     * @dev Get total number of stakes for user
     */
    function getUserStakeCount(address _user) external view returns (uint256) {
        return userStakes[_user].length;
    }
    
    /**
     * @dev Get all stakes for user
     */
    function getUserStakes(address _user) external view returns (UserStake[] memory) {
        return userStakes[_user];
    }
    
    /**
     * @dev Get reward breakdown for user stake
     */
    function getRewardBreakdown(address _user, uint256 _stakeIndex)
        external view returns (
            uint256 claimableRewardsUSDT,
            uint256 alreadyClaimedUSDT,
            bool shouldAutoBurn,
            uint256 daysUntilBurn
        ) 
    {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        (claimableRewardsUSDT, shouldAutoBurn) = calculateAvailableRewards(_user, _stakeIndex);
        
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        alreadyClaimedUSDT = userStake.totalClaimedReward;
        
        // Calculate days until burn
        if (block.timestamp >= userStake.endTime) {
            daysUntilBurn = 0;
        } else {
            daysUntilBurn = (userStake.endTime - block.timestamp) / 1 days;
        }
        
        return (claimableRewardsUSDT, alreadyClaimedUSDT, shouldAutoBurn, daysUntilBurn);
    }
    
    /**
     * @dev Get staking statistics
     */
    function getStakingStats() external view returns (
        uint256 totalActiveStakes,
        uint256 totalUSDTDistributed,
        uint256 totalBurned,
        uint256 usdtReserveBalance,
        uint256 totalPresaleSoldAmount,
        uint256 remainingPresaleSupply
    ) {
        return (
            activeStakeCount,
            totalStakingDistributed,
            totalTokensBurned,
            stakingUSDTReserves,
            totalPresaleSold,
            presaleSupply
        );
    }
    
    /**
     * @dev Get presale information
     */
    function getPresaleInfo() external view returns (
        uint256 currentPrice,
        uint256 remainingSupply,
        uint256 totalSold,
        address treasury,
        bool active
    ) {
        return (
            ozonePrice,
            presaleSupply,
            totalPresaleSold,
            treasuryWallet,
            presaleActive
        );
    }
    
    /**
     * @dev Get OZONE contract Proof of Reserves
     */
    function getOZONEProofOfReserves() external view returns (
        uint256 treasuryBalance,
        uint256 monthlyProfit,
        uint256 distributedRewards,
        uint256 availableForRewards
    ) {
        return ozoneContract.getProofOfReserves();
    }
    
    /**
     * @dev Get contract version
     */
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }
    
    /**
     * @dev Get total active stakes
     */
    function getTotalActiveStakes() external view returns (uint256) {
        return activeStakeCount;
    }
    
    /**
     * @dev Get time until next claim for a stake
     */
    function getTimeUntilNextClaim(address _user, uint256 _stakeIndex) external view returns (uint256) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        
        if (block.timestamp >= userStake.nextClaimTime) {
            return 0;
        }
        
        return userStake.nextClaimTime - block.timestamp;
    }
    
    // =============================================================================
    // UPGRADE AUTHORIZATION
    // =============================================================================
    
    /**
     * @dev Function that authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        emit ContractUpgraded(newImplementation, block.timestamp);
    }
}

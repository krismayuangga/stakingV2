// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 ██████╗ ███████╗ ██████╗ ███╗   ██╗███████╗
██╔═══██╗╚══███╔╝██╔═══██╗████╗  ██║██╔════╝
██║   ██║  ███╔╝ ██║   ██║██╔██╗ ██║█████╗  
██║   ██║ ███╔╝  ██║   ██║██║╚██╗██║██╔══╝  
╚██████╔╝███████╗╚██████╔╝██║ ╚████║███████╗
 ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    🏭 OZONE STAKING V2 - Dual Reward Staking Platform
    
    ════════════════════════════════════════════════════════════════════
    │  🎯 Auto-Tier System: 5 Pools Based on USDT Value              │
    │  💰 LimoX Pools: $100-$5,000 (6-8% Monthly APY)                │
    │  💎 SaproX Pools: $5,001+ (9-10% Monthly APY)                  │
    │  ⏰ Claim Every 15 Days (Time-Based)                            │
    │  🔥 Auto-Burn Principal at 300% Max Reward                     │
    │  🔄 UUPS Upgradeable for Future Enhancements                   │
    ════════════════════════════════════════════════════════════════════
    
    💡 Stake OZONE → Earn USDT or OZONE rewards daily
       Tier locked at stake time for fairness & predictability
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
 * @title OzoneStakingV2 - Production Dual Reward Staking Platform
 * @dev UUPS Upgradeable staking system with auto-tier and time-based claims
 * @notice Gas-optimized deployment for BSC Mainnet (v2.0 - Upgradeable)
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
     * @dev Reward type selection for dual reward system
     */
    enum RewardType {
        USDT_ONLY,    // 0: User receives rewards in USDT
        OZONE_ONLY    // 1: User receives rewards in OZONE
    }
    
    /**
     * @dev Pool structure dengan dual reward capabilities
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
        bool allowOzoneRewards;        // Allow OZONE rewards option
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
        uint256 totalUsdtClaimed;      // Total USDT rewards claimed
        uint256 totalOzoneClaimed;     // Total OZONE rewards claimed
        RewardType preferredRewardType; // User's preferred reward type
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
    uint256 public ozoneReserves;            // OZONE reserves untuk dual rewards
    uint256 public totalStakingDistributed;  // Total USDT distributed
    uint256 public totalOzoneDistributed;    // Total OZONE distributed
    uint256 public totalTokensBurned;        // Total OZONE burned
    uint256 public activeStakeCount;         // Active stakes count
    
    // Authorization untuk Presale Contract
    mapping(address => bool) public authorizedStakeCreators;
    
    // Constants - Production Configuration
    uint256 public constant MAX_REWARD_PERCENTAGE = 30000; // 300% maximum
    uint256 public constant CLAIM_INTERVAL = 15 days;      // 15 days claim interval
    uint256 public constant MONTH_DURATION = 30 days;      // 30 days = 1 month
    
    // Price Management
    uint256 public ozonePrice; // OZONE price in USDT (18 decimals)
    
    // Contract Version
    string public constant VERSION = "2.0.0-UUPS"; // Upgradeable version
    
    // =============================================================================
    // EVENTS
    // =============================================================================
    
    // Staking Events
    event UserStaked(address indexed user, uint256 indexed poolId, uint256 ozoneAmount, uint256 usdtValue, uint256 stakeIndex);
    event StakeCreatedForUser(address indexed user, address indexed creator, uint256 poolId, uint256 ozoneAmount, uint256 usdtValue);
    event UserUnstaked(address indexed user, uint256 indexed stakeIndex, uint256 amount);
    
    // Reward Events
    event RewardClaimed(
        address indexed user,
        uint256 indexed stakeIndex,
        uint256 baseRewards,
        uint256 usdtAmount,
        uint256 ozoneAmount,
        RewardType rewardType
    );
    event TokensAutoBurned(address indexed user, uint256 indexed stakeIndex, uint256 burnedAmount, uint256 totalRewardsClaimed);
    
    // Pool Events
    event PoolCreated(uint256 indexed poolId, string name, uint256 monthlyAPY, uint256 minUSDT, uint256 maxUSDT);
    event PoolUpdated(uint256 indexed poolId, string name, uint256 monthlyAPY);
    event PoolDeactivated(uint256 indexed poolId, string reason);
    
    // Reserve Events
    event USDTReservesFunded(uint256 amount);
    event USDTReservesWithdrawn(uint256 amount);
    event OzoneReservesFunded(uint256 amount);
    event OzoneReservesWithdrawn(uint256 amount);
    
    // Price Events
    event OzonePriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    
    // Authorization Events
    event AuthorizedStakeCreatorUpdated(address indexed creator, bool status);
    
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
        uint256 _initialOzonePrice
    ) public initializer {
        require(_ozoneToken != address(0), "Invalid OZONE token");
        require(_usdtToken != address(0), "Invalid USDT token");
        require(_ozoneContract != address(0), "Invalid OZONE contract");
        require(_initialOzonePrice > 0, "Invalid price");
        
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        ozoneToken = IERC20(_ozoneToken);
        usdtToken = IERC20(_usdtToken);
        ozoneContract = IOZONEToken(_ozoneContract);
        ozonePrice = _initialOzonePrice;
        
        nextPoolId = 1;
        totalPools = 0;
        
        // Initialize 5 pools (LimoX A/B/C, SaproX A/B)
        _initializePools();
    }
    
    /**
     * @dev Initialize default 5-tier pool system
     */
    function _initializePools() private {
        // LimoX Pool A: $100 - $1,000 (6% monthly APY)
        _createPool(
            "LimoX Pool A",
            600,                    // 6% APY
            100 * 10**6,           // Min $100 USDT
            1000 * 10**6,          // Max $1,000 USDT
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true,                   // enableAutoBurn
            true                    // allowOzoneRewards
        );
        
        // LimoX Pool B: $1,001 - $3,000 (7% monthly APY)
        _createPool(
            "LimoX Pool B",
            700,                    // 7% APY
            1001 * 10**6,          // Min $1,001 USDT
            3000 * 10**6,          // Max $3,000 USDT
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true,
            true
        );
        
        // LimoX Pool C: $3,001 - $5,000 (8% monthly APY)
        _createPool(
            "LimoX Pool C",
            800,                    // 8% APY
            3001 * 10**6,          // Min $3,001 USDT
            5000 * 10**6,          // Max $5,000 USDT
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true,
            true
        );
        
        // SaproX Pool A: $5,001 - $10,000 (9% monthly APY)
        _createPool(
            "SaproX Pool A",
            900,                    // 9% APY
            5001 * 10**6,          // Min $5,001 USDT
            10000 * 10**6,         // Max $10,000 USDT
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true,
            true
        );
        
        // SaproX Pool B: $10,001+ (10% monthly APY)
        _createPool(
            "SaproX Pool B",
            1000,                   // 10% APY
            10001 * 10**6,         // Min $10,001 USDT
            0,                      // No max (unlimited)
            CLAIM_INTERVAL,
            MAX_REWARD_PERCENTAGE,
            true,
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
        uint256 _minStakeUSDT,
        uint256 _maxStakeUSDT,
        uint256 _claimInterval,
        uint256 _maxRewardPercent,
        bool _enableAutoBurn,
        bool _allowOzoneRewards
    ) private {
        uint256 poolId = nextPoolId;
        
        pools[poolId] = Pool({
            name: _name,
            monthlyAPY: _monthlyAPY,
            minStakeUSDT: _minStakeUSDT,
            maxStakeUSDT: _maxStakeUSDT,
            claimInterval: _claimInterval,
            maxRewardPercent: _maxRewardPercent,
            enableAutoBurn: _enableAutoBurn,
            totalStaked: 0,
            totalClaimed: 0,
            isActive: true,
            createdAt: block.timestamp,
            allowOzoneRewards: _allowOzoneRewards
        });
        
        nextPoolId++;
        totalPools++;
        
        emit PoolCreated(poolId, _name, _monthlyAPY, _minStakeUSDT, _maxStakeUSDT);
    }
    
    /**
     * @dev Update existing pool (only owner)
     */
    function updatePool(
        uint256 _poolId,
        string memory _name,
        uint256 _monthlyAPY,
        uint256 _minStakeUSDT,
        uint256 _maxStakeUSDT,
        uint256 _claimInterval,
        uint256 _maxRewardPercent,
        bool _enableAutoBurn,
        bool _allowOzoneRewards
    ) external onlyOwner {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        require(_monthlyAPY > 0 && _monthlyAPY <= 10000, "Invalid APY");
        require(_claimInterval >= 1 days, "Claim interval too short");
        require(_maxRewardPercent >= 10000, "Max reward must be at least 100%");
        
        Pool storage pool = pools[_poolId];
        pool.name = _name;
        pool.monthlyAPY = _monthlyAPY;
        pool.minStakeUSDT = _minStakeUSDT;
        pool.maxStakeUSDT = _maxStakeUSDT;
        pool.claimInterval = _claimInterval;
        pool.maxRewardPercent = _maxRewardPercent;
        pool.enableAutoBurn = _enableAutoBurn;
        pool.allowOzoneRewards = _allowOzoneRewards;
        
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
    
    /**
     * @dev Determine pool ID berdasarkan USDT value (auto-tier selection)
     */
    function determinePoolByUSDTValue(uint256 usdtValue) public view returns (uint256) {
        // Check from highest tier to lowest
        for (uint256 i = nextPoolId - 1; i >= 1; i--) {
            Pool memory pool = pools[i];
            if (!pool.isActive) continue;
            
            // Check if USDT value fits in this pool's range
            if (usdtValue >= pool.minStakeUSDT) {
                if (pool.maxStakeUSDT == 0 || usdtValue <= pool.maxStakeUSDT) {
                    return i;
                }
            }
        }
        
        revert("No suitable pool found for USDT value");
    }
    
    // =============================================================================
    // STAKING FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Stake OZONE tokens ke pool tertentu (manual selection by OZONE holders)
     */
    function stake(uint256 _poolId, uint256 _amount) external nonReentrant whenNotPaused {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        require(_amount > 0, "Amount must be greater than 0");
        
        Pool memory pool = pools[_poolId];
        require(pool.isActive, "Pool is not active");
        
        // Calculate USDT value berdasarkan current OZONE price
        uint256 usdtValue = (_amount * ozonePrice) / 10**18;
        
        // Validate USDT value fits pool range
        require(usdtValue >= pool.minStakeUSDT, "Below minimum stake for this pool");
        if (pool.maxStakeUSDT > 0) {
            require(usdtValue <= pool.maxStakeUSDT, "Above maximum stake for this pool");
        }
        
        // Transfer OZONE from user
        require(ozoneToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        // Create stake entry
        _createStakeEntry(msg.sender, _poolId, _amount, _amount, usdtValue, pool.monthlyAPY);
        
        emit UserStaked(msg.sender, _poolId, _amount, usdtValue, userStakes[msg.sender].length - 1);
    }
    
    /**
     * @dev Create stake for user (called by authorized contracts like Presale)
     * @notice This function allows Presale contract to create stakes on behalf of users
     */
    function createStakeForUser(
        address _user,
        uint256 _poolId,
        uint256 _ozoneAmount,
        uint256 _usdtValue
    ) external nonReentrant whenNotPaused {
        require(authorizedStakeCreators[msg.sender], "Not authorized to create stakes");
        require(_user != address(0), "Invalid user address");
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        require(_ozoneAmount > 0, "Amount must be greater than 0");
        require(_usdtValue > 0, "USDT value must be greater than 0");
        
        Pool memory pool = pools[_poolId];
        require(pool.isActive, "Pool is not active");
        
        // Validate USDT value fits pool range
        require(_usdtValue >= pool.minStakeUSDT, "Below minimum stake for this pool");
        if (pool.maxStakeUSDT > 0) {
            require(_usdtValue <= pool.maxStakeUSDT, "Above maximum stake for this pool");
        }
        
        // Transfer OZONE from caller (Presale contract should have the tokens)
        require(ozoneToken.transferFrom(msg.sender, address(this), _ozoneAmount), "Transfer failed");
        
        // Create stake entry
        _createStakeEntry(_user, _poolId, _ozoneAmount, _ozoneAmount, _usdtValue, pool.monthlyAPY);
        
        emit StakeCreatedForUser(_user, msg.sender, _poolId, _ozoneAmount, _usdtValue);
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
        uint256 _lockedAPY
    ) private {
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
            totalUsdtClaimed: 0,
            totalOzoneClaimed: 0,
            preferredRewardType: RewardType.USDT_ONLY // Default to USDT
        }));
        
        pools[_poolId].totalStaked += _amount;
        activeStakeCount++;
    }
    
    // =============================================================================
    // REWARD CALCULATION
    // =============================================================================
    
    /**
     * @dev Calculate available rewards untuk stake tertentu
     * @notice Rewards calculated daily based on locked APY at stake time
     */
    function calculateAvailableRewards(address _user, uint256 _stakeIndex) 
        public view returns (uint256 claimableRewards, bool shouldAutoBurn) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        if (!userStake.isActive || userStake.isBurned) return (0, false);
        
        // Calculate time elapsed in days
        uint256 timeElapsed = block.timestamp - userStake.lastClaimTime;
        uint256 daysElapsed = timeElapsed / 1 days;
        
        if (daysElapsed == 0) return (0, false);
        
        // Calculate daily reward using LOCKED APY
        // Daily reward = (originalAmount * lockedAPY) / 10000 / 30
        uint256 dailyReward = (userStake.originalAmount * userStake.lockedAPY) / 10000 / 30;
        uint256 totalReward = dailyReward * daysElapsed;
        
        // Calculate USDT value of rewards
        uint256 totalRewardUSDT = (totalReward * ozonePrice) / 10**18;
        
        // Check maximum reward (300% of USDT value at stake)
        uint256 maxRewardUSDT = (userStake.usdtValueAtStake * MAX_REWARD_PERCENTAGE) / 10000;
        uint256 remainingRewardUSDT = maxRewardUSDT - userStake.totalClaimedReward;
        
        if (totalRewardUSDT > remainingRewardUSDT) {
            totalRewardUSDT = remainingRewardUSDT;
        }
        
        // Check if should auto-burn
        shouldAutoBurn = false;
        Pool memory pool = pools[userStake.poolId];
        if (pool.enableAutoBurn && userStake.totalClaimedReward + totalRewardUSDT >= maxRewardUSDT) {
            shouldAutoBurn = true;
        }
        
        return (totalRewardUSDT, shouldAutoBurn);
    }
    
    /**
     * @dev Calculate reward distribution berdasarkan reward type
     */
    function calculateRewardDistribution(
        uint256 _baseRewardsUSDT,
        RewardType _rewardType
    ) public view returns (uint256 usdtAmount, uint256 ozoneAmount) {
        
        if (_rewardType == RewardType.USDT_ONLY) {
            usdtAmount = _baseRewardsUSDT;
            ozoneAmount = 0;
            
        } else if (_rewardType == RewardType.OZONE_ONLY) {
            usdtAmount = 0;
            // Convert USDT value to OZONE amount
            ozoneAmount = (_baseRewardsUSDT * 10**18) / ozonePrice;
        }
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
     * @dev Claim rewards dengan default USDT_ONLY (backward compatible)
     */
    function claimRewards(uint256 _stakeIndex) external nonReentrant {
        _claimRewards(_stakeIndex, RewardType.USDT_ONLY);
    }
    
    /**
     * @dev Claim rewards dengan reward type selection
     */
    function claimRewardsWithType(uint256 _stakeIndex, RewardType _rewardType) 
        external nonReentrant {
        _claimRewards(_stakeIndex, _rewardType);
    }
    
    /**
     * @dev Internal claim logic
     */
    function _claimRewards(uint256 _stakeIndex, RewardType _rewardType) internal whenNotPaused {
        require(_stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        require(canClaim(msg.sender, _stakeIndex), "Cannot claim yet - must wait 15 days");
        
        UserStake storage userStake = userStakes[msg.sender][_stakeIndex];
        Pool memory pool = pools[userStake.poolId];
        
        // Validate reward type untuk pool
        if (_rewardType == RewardType.OZONE_ONLY) {
            require(pool.allowOzoneRewards, "OZONE rewards not allowed for this pool");
        }
        
        (uint256 baseRewards, bool shouldAutoBurn) = calculateAvailableRewards(msg.sender, _stakeIndex);
        require(baseRewards > 0, "No rewards available");
        
        // Calculate reward distribution
        (uint256 usdtAmount, uint256 ozoneAmount) = calculateRewardDistribution(baseRewards, _rewardType);
        
        // Validate reserves
        require(usdtAmount <= stakingUSDTReserves, "Insufficient USDT reserves");
        require(ozoneAmount <= ozoneReserves, "Insufficient OZONE reserves");
        
        // Update stake data
        userStake.lastClaimTime = block.timestamp;
        userStake.totalClaimedReward += baseRewards;
        userStake.totalUsdtClaimed += usdtAmount;
        userStake.totalOzoneClaimed += ozoneAmount;
        userStake.preferredRewardType = _rewardType;
        userStake.nextClaimTime = block.timestamp + pool.claimInterval;
        
        // Transfer rewards
        if (usdtAmount > 0) {
            stakingUSDTReserves -= usdtAmount;
            totalStakingDistributed += usdtAmount;
            require(usdtToken.transfer(msg.sender, usdtAmount), "USDT transfer failed");
        }
        
        if (ozoneAmount > 0) {
            ozoneReserves -= ozoneAmount;
            totalOzoneDistributed += ozoneAmount;
            require(ozoneToken.transfer(msg.sender, ozoneAmount), "OZONE transfer failed");
        }
        
        // Update pool stats
        pools[userStake.poolId].totalClaimed += baseRewards;
        
        emit RewardClaimed(msg.sender, _stakeIndex, baseRewards, usdtAmount, ozoneAmount, _rewardType);
        
        // Auto-burn if enabled and reached max reward
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
    // ADMIN FUNCTIONS
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
     * @dev Fund OZONE reserves untuk dual rewards
     */
    function fundOzoneReserves(uint256 _amount) external onlyOwner {
        require(ozoneToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        ozoneReserves += _amount;
        emit OzoneReservesFunded(_amount);
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
    
    /**
     * @dev Withdraw OZONE reserves (emergency only)
     */
    function withdrawOzoneReserves(uint256 _amount) external onlyOwner {
        require(_amount <= ozoneReserves, "Insufficient reserves");
        ozoneReserves -= _amount;
        require(ozoneToken.transfer(owner(), _amount), "Transfer failed");
        emit OzoneReservesWithdrawn(_amount);
    }
    
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
     * @dev Set authorized stake creator (for Presale contract)
     */
    function setAuthorizedStakeCreator(address _creator, bool _status) external onlyOwner {
        authorizedStakeCreators[_creator] = _status;
        emit AuthorizedStakeCreatorUpdated(_creator, _status);
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
    function getRewardBreakdown(address _user, uint256 _stakeIndex, RewardType _rewardType)
        external view returns (
            uint256 claimableRewardsUSDT,
            uint256 usdtAmount,
            uint256 ozoneAmount,
            uint256 alreadyClaimedUSDT,
            bool shouldAutoBurn
        ) 
    {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        (claimableRewardsUSDT, shouldAutoBurn) = calculateAvailableRewards(_user, _stakeIndex);
        (usdtAmount, ozoneAmount) = calculateRewardDistribution(claimableRewardsUSDT, _rewardType);
        
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        alreadyClaimedUSDT = userStake.totalClaimedReward;
        
        return (claimableRewardsUSDT, usdtAmount, ozoneAmount, alreadyClaimedUSDT, shouldAutoBurn);
    }
    
    /**
     * @dev Get staking statistics
     */
    function getStakingStats() external view returns (
        uint256 totalActiveStakes,
        uint256 totalUSDTDistributed,
        uint256 totalOZONEDistributed,
        uint256 totalBurned,
        uint256 usdtReserveBalance,
        uint256 ozoneReserveBalance
    ) {
        return (
            activeStakeCount,
            totalStakingDistributed,
            totalOzoneDistributed,
            totalTokensBurned,
            stakingUSDTReserves,
            ozoneReserves
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

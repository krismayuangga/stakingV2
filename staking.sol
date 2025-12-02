/**
 *Submitted for verification at BscScan.com on 2025-10-09
*/

// Sources flattened with hardhat v2.26.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/Pausable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}


// File contracts/OzoneXStaking.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;
/**
 * @title OzoneXStaking - Production Dual Reward Staking Platform
 * @dev Mainnet-optimized staking system with USDT and OZONE reward choices
 * @notice Gas-optimized deployment for BSC Mainnet (v2.0)
 * @author OZONE Team - Deployed October 2025
 */

// Interface untuk OZONE Token PoR integration
interface IOZONEToken {
    function getProofOfReserves() external view returns (uint256 ozoneReserves, uint256 usdtReserves);
}

contract OzoneXStaking is ReentrancyGuard, Ownable, Pausable {
    
    // =============================================================================
    // ENUMS & STRUCTS
    // =============================================================================
    
    /**
     * @dev Reward type options untuk dual reward system
     */
    enum RewardType {
        USDT_ONLY,      // 0: 100% USDT (default)
        OZONE_ONLY      // 1: 100% OZONE
    }
    
    /**
     * @dev Pool structure dengan dual reward capabilities
     */
    struct Pool {
        string name;                    // Pool name
        uint256 monthlyAPY;            // Monthly APY dalam basis points (1000 = 10%)
        uint256 minStake;              // Minimum stake amount
        uint256 maxStake;              // Maximum stake amount (0 = unlimited)
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
        uint256 amount;                // Amount received by contract (after tax)
        uint256 originalAmount;        // Original amount staked (before tax) - untuk reward calculation
        uint256 poolId;                // Pool ID
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
    IERC20 public immutable ozoneToken;
    IERC20 public immutable usdtToken;
    IOZONEToken public immutable ozoneContract;
    
    // Pool Management
    mapping(uint256 => Pool) public pools;
    mapping(address => UserStake[]) public userStakes;
    uint256 public totalPools = 0;
    uint256 public nextPoolId = 1;
    
    // Reserve Management
    uint256 public stakingUSDTReserves;      // USDT reserves untuk staking rewards
    uint256 public ozoneReserves;            // OZONE reserves untuk dual rewards
    uint256 public totalStakingDistributed;  // Total USDT distributed
    uint256 public totalOzoneDistributed;    // Total OZONE distributed
    uint256 public totalTokensBurned;        // Total OZONE burned
    uint256 public activeStakeCount;         // Active stakes count
    
    // Constants - Production Configuration
    uint256 public constant MAX_REWARD_PERCENTAGE = 30000; // 300% maximum
    uint256 public constant DEFAULT_CLAIM_INTERVAL = 1296000; // 15 days in seconds
    uint256 public constant MONTH_DURATION = 2592000; // 30 days in seconds
    
    // Price Management
    uint256 public ozonePrice = 1e18; // Default 1 USDT = 1 OZONE (18 decimals)
    
    // Contract Version
    string public constant VERSION = "2.0.0"; // Production mainnet version
    
    // =============================================================================
    // EVENTS
    // =============================================================================
    
    // Staking Events
    event UserStaked(address indexed user, uint256 indexed poolId, uint256 amount, uint256 stakeIndex);
    event UserUnstaked(address indexed user, uint256 indexed stakeIndex, uint256 amount);
    
    // Reward Events
    event RewardClaimed(
        address indexed user,
        uint256 indexed stakeIndex,
        uint256 baseReward,
        uint256 usdtAmount,
        uint256 ozoneAmount,
        RewardType rewardType
    );
    event TokensAutoBurned(address indexed user, uint256 indexed stakeIndex, uint256 burnedAmount, uint256 totalRewards);
    
    // Pool Events
    event PoolCreated(uint256 indexed poolId, string name, uint256 monthlyAPY, bool allowOzoneRewards);
    event PoolUpdated(uint256 indexed poolId, string name, uint256 monthlyAPY);
    event PoolDeactivated(uint256 indexed poolId, string reason);
    
    // Reserve Events
    event USDTReservesFunded(uint256 amount);
    event USDTReservesWithdrawn(uint256 amount);
    event OzoneReservesFunded(uint256 amount);
    event OzoneReservesWithdrawn(uint256 amount);
    
    // Price Events
    event OzonePriceUpdated(uint256 newPrice);
    
    // =============================================================================
    // CONSTRUCTOR
    // =============================================================================
    
    constructor(
        address _ozoneToken,
        address _usdtToken,
        address _ozoneContract
    ) Ownable(msg.sender) {
        require(_ozoneToken != address(0), "Invalid OZONE token");
        require(_usdtToken != address(0), "Invalid USDT token");
        require(_ozoneContract != address(0), "Invalid OZONE contract");
        
        ozoneToken = IERC20(_ozoneToken);
        usdtToken = IERC20(_usdtToken);
        ozoneContract = IOZONEToken(_ozoneContract);
        
        // No default pools - create after deployment for gas savings
    }
    
    // =============================================================================
    // POOL MANAGEMENT
    // =============================================================================
    
    /**
     * @dev Create new staking pool dengan dual reward options
     */
    function createPool(
        string memory _name,
        uint256 _monthlyAPY,
        uint256 _minStake,
        uint256 _maxStake,
        uint256 _claimInterval,
        uint256 _maxRewardPercent,
        bool _enableAutoBurn,
        bool _allowOzoneRewards
    ) external onlyOwner {
        require(_monthlyAPY > 0 && _monthlyAPY <= 10000, "Invalid APY"); // Max 100% APY
        require(_claimInterval >= 1 days, "Claim interval too short");
        require(_maxRewardPercent >= 10000, "Max reward must be at least 100%");
        
        uint256 poolId = nextPoolId;
        
        pools[poolId] = Pool({
            name: _name,
            monthlyAPY: _monthlyAPY,
            minStake: _minStake,
            maxStake: _maxStake,
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
        
        emit PoolCreated(poolId, _name, _monthlyAPY, _allowOzoneRewards);
    }
    
    /**
     * @dev Update existing pool
     */
    function updatePool(
        uint256 _poolId,
        string memory _name,
        uint256 _monthlyAPY,
        uint256 _minStake,
        uint256 _maxStake,
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
        pool.minStake = _minStake;
        pool.maxStake = _maxStake;
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
    
    // =============================================================================
    // STAKING FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Stake OZONE tokens ke pool tertentu
     */
    function stake(uint256 _poolId, uint256 _amount) external nonReentrant whenNotPaused {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        require(_amount > 0, "Amount must be greater than 0");
        
        Pool memory pool = pools[_poolId];
        require(pool.isActive, "Pool is not active");
        require(_amount >= pool.minStake, "Below minimum stake");
        require(pool.maxStake == 0 || _amount <= pool.maxStake, "Above maximum stake");
        
        // Transfer OZONE dari user ke contract
        require(ozoneToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        // Calculate amount after tax (assume 1% tax)
        uint256 afterTaxAmount = (_amount * 99) / 100;
        
        // Create new UserStake
        userStakes[msg.sender].push(UserStake({
            amount: afterTaxAmount,
            originalAmount: _amount,
            poolId: _poolId,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            totalClaimedReward: 0,
            nextClaimTime: block.timestamp + pool.claimInterval,
            isActive: true,
            isBurned: false,
            totalUsdtClaimed: 0,
            totalOzoneClaimed: 0,
            preferredRewardType: RewardType.USDT_ONLY
        }));
        
        // Update pool statistics
        pools[_poolId].totalStaked += afterTaxAmount;
        activeStakeCount++;
        
        uint256 stakeIndex = userStakes[msg.sender].length - 1;
        emit UserStaked(msg.sender, _poolId, _amount, stakeIndex);
    }
    
    // =============================================================================
    // REWARD CALCULATION
    // =============================================================================
    
    /**
     * @dev Calculate available rewards untuk stake tertentu
     */
    function calculateAvailableRewards(address _user, uint256 _stakeIndex) 
        public view returns (uint256, bool) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        if (!userStake.isActive || userStake.isBurned) return (0, false);
        
        Pool memory pool = pools[userStake.poolId];
        
        // Calculate time elapsed in days
        uint256 timeElapsed = block.timestamp - userStake.lastClaimTime;
        uint256 daysElapsed = timeElapsed / 1 days;
        
        if (daysElapsed == 0) return (0, false);
        
        // Calculate daily reward
        uint256 dailyReward = (userStake.originalAmount * pool.monthlyAPY) / 10000 / 30;
        uint256 totalReward = dailyReward * daysElapsed;
        
        // Check maximum reward (300%)
        uint256 maxReward = (userStake.originalAmount * pool.maxRewardPercent) / 10000;
        uint256 remainingReward = maxReward - userStake.totalClaimedReward;
        
        if (totalReward > remainingReward) {
            totalReward = remainingReward;
        }
        
        // Check if should auto-burn
        bool shouldAutoBurn = false;
        if (pool.enableAutoBurn && userStake.totalClaimedReward + totalReward >= maxReward) {
            shouldAutoBurn = true;
        }
        
        return (totalReward, shouldAutoBurn);
    }
    
    /**
     * @dev Calculate reward distribution berdasarkan reward type
     */
    function calculateRewardDistribution(
        uint256 _baseRewards,
        RewardType _rewardType
    ) public view returns (uint256 usdtAmount, uint256 ozoneAmount) {
        
        if (_rewardType == RewardType.USDT_ONLY) {
            usdtAmount = _baseRewards;
            ozoneAmount = 0;
            
        } else if (_rewardType == RewardType.OZONE_ONLY) {
            usdtAmount = 0;
            ozoneAmount = (_baseRewards * 1e18) / ozonePrice;
        }
    }
    
    // =============================================================================
    // CLAIM FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Check if user can claim rewards
     */
    function canClaim(address _user, uint256 _stakeIndex) public view returns (bool) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        UserStake memory userStake = userStakes[_user][_stakeIndex];
        if (!userStake.isActive || userStake.isBurned) return false;
        
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
        require(canClaim(msg.sender, _stakeIndex), "Cannot claim yet");
        
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
     * @dev Manual unstake before reaching 300%
     */
    function unstake(uint256 _stakeIndex) external nonReentrant whenNotPaused {
        require(_stakeIndex < userStakes[msg.sender].length, "Invalid stake index");
        
        UserStake storage userStake = userStakes[msg.sender][_stakeIndex];
        require(userStake.isActive && !userStake.isBurned, "Stake is not active");
        
        // Claim pending rewards if possible
        if (canClaim(msg.sender, _stakeIndex)) {
            (uint256 pendingRewards,) = calculateAvailableRewards(msg.sender, _stakeIndex);
            if (pendingRewards > 0) {
                _claimRewards(_stakeIndex, userStake.preferredRewardType);
            }
        }
        
        uint256 unstakeAmount = userStake.amount;
        
        // Mark as inactive
        userStake.isActive = false;
        
        // Update stats
        pools[userStake.poolId].totalStaked -= unstakeAmount;
        activeStakeCount--;
        
        // Return staked tokens
        require(ozoneToken.transfer(msg.sender, unstakeAmount), "Transfer failed");
        
        emit UserUnstaked(msg.sender, _stakeIndex, unstakeAmount);
    }
    
    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Fund USDT reserves
     */
    function fundUSDTReserves(uint256 _amount) external onlyOwner {
        require(usdtToken.transferFrom(msg.sender, address(this), _amount), "USDT transfer failed");
        stakingUSDTReserves += _amount;
        emit USDTReservesFunded(_amount);
    }
    
    /**
     * @dev Fund OZONE reserves
     */
    function fundOzoneReserves(uint256 _amount) external onlyOwner {
        require(ozoneToken.transferFrom(msg.sender, address(this), _amount), "OZONE transfer failed");
        ozoneReserves += _amount;
        emit OzoneReservesFunded(_amount);
    }
    
    /**
     * @dev Withdraw USDT reserves
     */
    function withdrawUSDTReserves(uint256 _amount) external onlyOwner {
        require(_amount <= stakingUSDTReserves, "Insufficient USDT reserves");
        stakingUSDTReserves -= _amount;
        require(usdtToken.transfer(owner(), _amount), "USDT transfer failed");
        emit USDTReservesWithdrawn(_amount);
    }
    
    /**
     * @dev Withdraw OZONE reserves
     */
    function withdrawOzoneReserves(uint256 _amount) external onlyOwner {
        require(_amount <= ozoneReserves, "Insufficient OZONE reserves");
        ozoneReserves -= _amount;
        require(ozoneToken.transfer(owner(), _amount), "OZONE transfer failed");
        emit OzoneReservesWithdrawn(_amount);
    }
    
    /**
     * @dev Set OZONE price untuk conversions
     */
    function setOzonePrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price must be greater than 0");
        ozonePrice = _price;
        emit OzonePriceUpdated(_price);
    }
    
    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Get pool details
     */
    function getPool(uint256 _poolId) external view returns (Pool memory) {
        require(_poolId > 0 && _poolId < nextPoolId, "Pool does not exist");
        return pools[_poolId];
    }
    
    /**
     * @dev Get user stake details
     */
    function getUserStake(address _user, uint256 _stakeIndex) external view returns (UserStake memory) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        return userStakes[_user][_stakeIndex];
    }
    
    /**
     * @dev Get user stake count
     */
    function getUserStakeCount(address _user) external view returns (uint256) {
        return userStakes[_user].length;
    }
    
    /**
     * @dev Get reward breakdown untuk different reward types
     */
    function getRewardBreakdown(address _user, uint256 _stakeIndex, RewardType _rewardType)
        external view returns (
            uint256 totalRewards,
            uint256 usdtAmount,
            uint256 ozoneAmount,
            uint256 currentOzonePrice,
            bool canClaimNow
        ) {
        require(_stakeIndex < userStakes[_user].length, "Invalid stake index");
        
        (uint256 baseRewards,) = calculateAvailableRewards(_user, _stakeIndex);
        (uint256 usdt, uint256 ozone) = calculateRewardDistribution(baseRewards, _rewardType);
        
        return (
            baseRewards,
            usdt,
            ozone,
            ozonePrice,
            canClaim(_user, _stakeIndex)
        );
    }
    
    /**
     * @dev Get staking statistics
     */
    function getStakingStats() external view returns (
        uint256 totalStaked,
        uint256 totalUSDTDistributed,
        uint256 totalOZONEDistributed,
        uint256 totalBurned,
        uint256 activeStakes,
        uint256 usdtReserveBalance,
        uint256 ozoneReserveBalance
    ) {
        uint256 totalStakedAmount = 0;
        for (uint256 i = 1; i < nextPoolId; i++) {
            totalStakedAmount += pools[i].totalStaked;
        }
        
        return (
            totalStakedAmount,
            totalStakingDistributed,
            totalOzoneDistributed,
            totalTokensBurned,
            activeStakeCount,
            stakingUSDTReserves,
            ozoneReserves
        );
    }
    
    /**
     * @dev Get OZONE PoR for frontend display
     */
    function getOZONEProofOfReserves() external view returns (uint256 ozoneReserves, uint256 usdtReserves) {
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
    
    // =============================================================================
    // EMERGENCY FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Pause all operations
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause all operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency withdraw (only when paused)
     */
    function emergencyWithdrawUSDT(uint256 _amount) external onlyOwner whenPaused {
        require(usdtToken.transfer(owner(), _amount), "Transfer failed");
    }
    
    /**
     * @dev Emergency withdraw OZONE (only when paused)
     */
    function emergencyWithdrawOZONE(uint256 _amount) external onlyOwner whenPaused {
        require(ozoneToken.transfer(owner(), _amount), "Transfer failed");
    }
}
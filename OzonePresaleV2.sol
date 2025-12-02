// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 ██████╗ ███████╗ ██████╗ ███╗   ██╗███████╗
██╔═══██╗╚══███╔╝██╔═══██╗████╗  ██║██╔════╝
██║   ██║  ███╔╝ ██║   ██║██╔██╗ ██║█████╗  
██║   ██║ ███╔╝  ██║   ██║██║╚██╗██║██╔══╝  
╚██████╔╝███████╗╚██████╔╝██║ ╚████║███████╗
 ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    🏭 OZONE PRESALE V2 - Auto-Stake Presale Platform
    
    ════════════════════════════════════════════════════════════════════
    │  💳 Payment: USDT BEP-20 Only                                    │
    │  🤖 Price: Real-time from Chainlink/DEX Oracle                   │
    │  🎯 Auto-Tier: Based on USDT Investment Amount                   │
    │  🔒 Anti-Dump: OZONE Never Goes to User Wallet                   │
    │  ⚡ One-Click: Buy OZONE → Auto-Stake (1 Transaction)            │
    │  🔄 UUPS Upgradeable for Future Enhancements                     │
    ════════════════════════════════════════════════════════════════════
    
    💡 Invest USDT → Buy OZONE → Auto-stake → Earn rewards
       Pure passive income, no token management needed
*/

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Chainlink Price Feed Interface
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function decimals() external view returns (uint8);
}

// OzoneStakingV2 Interface
interface IOzoneStakingV2 {
    function createStakeForUser(
        address _user,
        uint256 _poolId,
        uint256 _ozoneAmount,
        uint256 _usdtValue
    ) external;
    
    function determinePoolByUSDTValue(uint256 usdtValue) external view returns (uint256);
}

/**
 * @title OzonePresaleV2 - Auto-Stake Presale Platform
 * @dev UUPS Upgradeable presale with oracle integration and auto-staking
 * @notice Buy OZONE with USDT and auto-stake in one transaction
 * @author OZONE Team - December 2025
 */
contract OzonePresaleV2 is
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
     * @dev Price source selection
     */
    enum PriceSource {
        MANUAL,      // Owner manually updates price
        CHAINLINK,   // Chainlink oracle
        DEX_TWAP     // DEX Time-Weighted Average Price
    }
    
    /**
     * @dev User purchase tracking
     */
    struct UserPurchase {
        uint256 usdtSpent;           // Total USDT spent
        uint256 ozoneReceived;       // Total OZONE bought
        uint256 averagePrice;        // Average price paid
        uint256 poolId;              // Pool tier assigned
        uint256 timestamp;           // Purchase timestamp
        uint256 stakeIndex;          // Index in staking contract
    }
    
    // =============================================================================
    // STATE VARIABLES
    // =============================================================================
    
    // Token References
    IERC20 public ozoneToken;
    IERC20 public usdtToken;
    IOzoneStakingV2 public stakingContract;
    
    // Price Oracle
    AggregatorV3Interface public chainlinkPriceFeed;
    PriceSource public priceSource;
    uint256 public manualOzonePrice;        // Fallback manual price (18 decimals)
    uint256 public lastPriceUpdate;
    uint256 public constant MAX_PRICE_AGE = 1 hours; // Max age for oracle price
    
    // Treasury & Limits
    address public treasuryWallet;
    uint256 public minPurchaseUSDT;         // Minimum purchase (default $100)
    uint256 public maxPurchaseUSDT;         // Maximum purchase per transaction (0 = unlimited)
    
    // Purchase Tracking
    mapping(address => UserPurchase[]) public userPurchases;
    mapping(address => uint256) public totalUSDTSpent;
    mapping(address => uint256) public totalOZONEReceived;
    
    // Statistics
    uint256 public totalUSDTRaised;
    uint256 public totalOZONESold;
    uint256 public totalPurchases;
    uint256 public uniqueBuyers;
    
    // Supply Management
    uint256 public presaleSupply;           // Total OZONE allocated for presale
    uint256 public remainingSupply;         // Remaining OZONE available
    
    // Price Bounds (for manual price updates)
    uint256 public minAllowedPrice;         // Minimum allowed price
    uint256 public maxAllowedPrice;         // Maximum allowed price
    uint256 public maxPriceChangePercent;   // Max price change per update (basis points)
    
    // Contract Version
    string public constant VERSION = "2.0.0-UUPS";
    
    // =============================================================================
    // EVENTS
    // =============================================================================
    
    // Purchase Events
    event TokensPurchased(
        address indexed buyer,
        uint256 usdtAmount,
        uint256 ozoneAmount,
        uint256 price,
        uint256 poolId,
        uint256 stakeIndex,
        uint256 timestamp
    );
    
    event BuyAndStakeCompleted(
        address indexed buyer,
        uint256 usdtSpent,
        uint256 ozoneReceived,
        uint256 poolTier,
        uint256 purchaseIndex
    );
    
    // Price Events
    event PriceSourceChanged(PriceSource indexed oldSource, PriceSource indexed newSource);
    event ManualPriceUpdated(uint256 oldPrice, uint256 newPrice, uint256 timestamp);
    event ChainlinkPriceFeedUpdated(address indexed oldFeed, address indexed newFeed);
    event PriceFetched(PriceSource source, uint256 price, uint256 timestamp);
    
    // Admin Events
    event TreasuryWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event StakingContractUpdated(address indexed oldContract, address indexed newContract);
    event PurchaseLimitsUpdated(uint256 minUSDT, uint256 maxUSDT);
    event PresaleSupplyUpdated(uint256 newSupply, uint256 remaining);
    event PriceBoundsUpdated(uint256 minPrice, uint256 maxPrice, uint256 maxChangePercent);
    
    // Emergency Events
    event EmergencyWithdraw(address indexed token, uint256 amount, address indexed to);
    event ContractUpgraded(address indexed newImplementation, uint256 timestamp);
    
    // =============================================================================
    // CONSTRUCTOR & INITIALIZER
    // =============================================================================
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @dev Initialize the contract
     */
    function initialize(
        address _ozoneToken,
        address _usdtToken,
        address _stakingContract,
        address _treasuryWallet,
        uint256 _initialPrice,
        uint256 _presaleSupply
    ) public initializer {
        require(_ozoneToken != address(0), "Invalid OZONE token");
        require(_usdtToken != address(0), "Invalid USDT token");
        require(_stakingContract != address(0), "Invalid staking contract");
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        require(_initialPrice > 0, "Invalid initial price");
        require(_presaleSupply > 0, "Invalid presale supply");
        
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        ozoneToken = IERC20(_ozoneToken);
        usdtToken = IERC20(_usdtToken);
        stakingContract = IOzoneStakingV2(_stakingContract);
        treasuryWallet = _treasuryWallet;
        
        // Set initial price (manual mode by default)
        priceSource = PriceSource.MANUAL;
        manualOzonePrice = _initialPrice;
        lastPriceUpdate = block.timestamp;
        
        // Set presale supply
        presaleSupply = _presaleSupply;
        remainingSupply = _presaleSupply;
        
        // Set default limits
        minPurchaseUSDT = 100 * 10**6;      // $100 minimum
        maxPurchaseUSDT = 0;                 // No maximum by default
        
        // Set default price bounds (for safety)
        minAllowedPrice = 0.01 * 10**18;    // $0.01 minimum
        maxAllowedPrice = 100 * 10**18;      // $100 maximum
        maxPriceChangePercent = 2000;        // 20% max change per update
    }
    
    // =============================================================================
    // PRICE ORACLE FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Get current OZONE price from active source
     * @return price OZONE price in USDT (18 decimals)
     */
    function getCurrentPrice() public view returns (uint256 price) {
        if (priceSource == PriceSource.CHAINLINK) {
            return _getPriceFromChainlink();
        } else if (priceSource == PriceSource.DEX_TWAP) {
            return _getPriceFromDEX();
        } else {
            return manualOzonePrice;
        }
    }
    
    /**
     * @dev Get price from Chainlink oracle
     */
    function _getPriceFromChainlink() private view returns (uint256) {
        require(address(chainlinkPriceFeed) != address(0), "Chainlink feed not set");
        
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            uint256 updatedAt,
            /* uint80 answeredInRound */
        ) = chainlinkPriceFeed.latestRoundData();
        
        require(price > 0, "Invalid Chainlink price");
        require(block.timestamp - updatedAt < MAX_PRICE_AGE, "Chainlink price stale");
        
        // Convert from Chainlink decimals (usually 8) to 18 decimals
        uint8 decimals = chainlinkPriceFeed.decimals();
        uint256 priceWithDecimals = uint256(price) * 10**(18 - decimals);
        
        return priceWithDecimals;
    }
    
    /**
     * @dev Get price from DEX TWAP (placeholder for future implementation)
     */
    function _getPriceFromDEX() private view returns (uint256) {
        // TODO: Implement DEX TWAP price fetching
        // For now, fallback to manual price
        return manualOzonePrice;
    }
    
    /**
     * @dev Set price source
     */
    function setPriceSource(PriceSource _newSource) external onlyOwner {
        PriceSource oldSource = priceSource;
        priceSource = _newSource;
        emit PriceSourceChanged(oldSource, _newSource);
    }
    
    /**
     * @dev Set Chainlink price feed address
     */
    function setChainlinkPriceFeed(address _priceFeed) external onlyOwner {
        require(_priceFeed != address(0), "Invalid price feed");
        address oldFeed = address(chainlinkPriceFeed);
        chainlinkPriceFeed = AggregatorV3Interface(_priceFeed);
        emit ChainlinkPriceFeedUpdated(oldFeed, _priceFeed);
    }
    
    /**
     * @dev Update manual OZONE price (with safety bounds)
     */
    function updateManualPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price must be positive");
        require(_newPrice >= minAllowedPrice, "Price below minimum");
        require(_newPrice <= maxAllowedPrice, "Price above maximum");
        
        // Check price change percentage
        if (manualOzonePrice > 0) {
            uint256 priceDiff;
            if (_newPrice > manualOzonePrice) {
                priceDiff = _newPrice - manualOzonePrice;
            } else {
                priceDiff = manualOzonePrice - _newPrice;
            }
            
            uint256 changePercent = (priceDiff * 10000) / manualOzonePrice;
            require(changePercent <= maxPriceChangePercent, "Price change too large");
        }
        
        uint256 oldPrice = manualOzonePrice;
        manualOzonePrice = _newPrice;
        lastPriceUpdate = block.timestamp;
        
        emit ManualPriceUpdated(oldPrice, _newPrice, block.timestamp);
    }
    
    /**
     * @dev Update price bounds for safety
     */
    function updatePriceBounds(
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _maxChangePercent
    ) external onlyOwner {
        require(_minPrice > 0, "Min price must be positive");
        require(_maxPrice > _minPrice, "Max price must be greater than min");
        require(_maxChangePercent <= 10000, "Max change cannot exceed 100%");
        
        minAllowedPrice = _minPrice;
        maxAllowedPrice = _maxPrice;
        maxPriceChangePercent = _maxChangePercent;
        
        emit PriceBoundsUpdated(_minPrice, _maxPrice, _maxChangePercent);
    }
    
    // =============================================================================
    // PRESALE FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Buy OZONE and auto-stake in one transaction
     * @param _usdtAmount Amount of USDT to spend
     */
    function buyAndStake(uint256 _usdtAmount) external nonReentrant whenNotPaused {
        require(_usdtAmount >= minPurchaseUSDT, "Below minimum purchase");
        if (maxPurchaseUSDT > 0) {
            require(_usdtAmount <= maxPurchaseUSDT, "Above maximum purchase");
        }
        
        // Get current OZONE price
        uint256 currentPrice = getCurrentPrice();
        require(currentPrice > 0, "Invalid price");
        
        // Calculate OZONE amount to buy
        // usdtAmount (6 decimals) * 10^18 / price (18 decimals) = ozoneAmount (18 decimals)
        uint256 ozoneAmount = (_usdtAmount * 10**18) / currentPrice;
        require(ozoneAmount > 0, "Amount too small");
        require(ozoneAmount <= remainingSupply, "Exceeds remaining supply");
        
        // Determine pool/tier based on USDT amount
        uint256 poolId = stakingContract.determinePoolByUSDTValue(_usdtAmount);
        
        // Transfer USDT from user to treasury
        require(usdtToken.transferFrom(msg.sender, treasuryWallet, _usdtAmount), "USDT transfer failed");
        
        // Update supply tracking
        remainingSupply -= ozoneAmount;
        
        // Approve staking contract to take OZONE
        require(ozoneToken.approve(address(stakingContract), ozoneAmount), "Approval failed");
        
        // Create stake for user via staking contract
        // This transfers OZONE from this contract to staking contract
        stakingContract.createStakeForUser(msg.sender, poolId, ozoneAmount, _usdtAmount);
        
        // Track purchase
        _recordPurchase(msg.sender, _usdtAmount, ozoneAmount, currentPrice, poolId);
        
        // Update statistics
        totalUSDTRaised += _usdtAmount;
        totalOZONESold += ozoneAmount;
        totalPurchases++;
        
        // Track unique buyers
        if (userPurchases[msg.sender].length == 1) {
            uniqueBuyers++;
        }
        
        emit TokensPurchased(
            msg.sender,
            _usdtAmount,
            ozoneAmount,
            currentPrice,
            poolId,
            userPurchases[msg.sender].length - 1,
            block.timestamp
        );
        
        emit BuyAndStakeCompleted(
            msg.sender,
            _usdtAmount,
            ozoneAmount,
            poolId,
            userPurchases[msg.sender].length - 1
        );
    }
    
    /**
     * @dev Record user purchase
     */
    function _recordPurchase(
        address _user,
        uint256 _usdtAmount,
        uint256 _ozoneAmount,
        uint256 _price,
        uint256 _poolId
    ) private {
        userPurchases[_user].push(UserPurchase({
            usdtSpent: _usdtAmount,
            ozoneReceived: _ozoneAmount,
            averagePrice: _price,
            poolId: _poolId,
            timestamp: block.timestamp,
            stakeIndex: userPurchases[_user].length
        }));
        
        totalUSDTSpent[_user] += _usdtAmount;
        totalOZONEReceived[_user] += _ozoneAmount;
    }
    
    // =============================================================================
    // ADMIN FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Update treasury wallet
     */
    function updateTreasuryWallet(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid treasury address");
        address oldTreasury = treasuryWallet;
        treasuryWallet = _newTreasury;
        emit TreasuryWalletUpdated(oldTreasury, _newTreasury);
    }
    
    /**
     * @dev Update staking contract address
     */
    function updateStakingContract(address _newStakingContract) external onlyOwner {
        require(_newStakingContract != address(0), "Invalid staking contract");
        address oldContract = address(stakingContract);
        stakingContract = IOzoneStakingV2(_newStakingContract);
        emit StakingContractUpdated(oldContract, _newStakingContract);
    }
    
    /**
     * @dev Update purchase limits
     */
    function updatePurchaseLimits(uint256 _minUSDT, uint256 _maxUSDT) external onlyOwner {
        require(_minUSDT > 0, "Min purchase must be positive");
        if (_maxUSDT > 0) {
            require(_maxUSDT >= _minUSDT, "Max must be >= min");
        }
        
        minPurchaseUSDT = _minUSDT;
        maxPurchaseUSDT = _maxUSDT;
        
        emit PurchaseLimitsUpdated(_minUSDT, _maxUSDT);
    }
    
    /**
     * @dev Add presale supply (fund OZONE to contract)
     */
    function addPresaleSupply(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be positive");
        require(ozoneToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        presaleSupply += _amount;
        remainingSupply += _amount;
        
        emit PresaleSupplyUpdated(presaleSupply, remainingSupply);
    }
    
    /**
     * @dev Emergency withdraw tokens
     */
    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner whenPaused {
        if (_token == address(0)) {
            payable(owner()).transfer(_amount);
        } else {
            require(IERC20(_token).transfer(owner(), _amount), "Transfer failed");
        }
        emit EmergencyWithdraw(_token, _amount, owner());
    }
    
    /**
     * @dev Pause contract
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
     * @dev Calculate OZONE amount for USDT
     */
    function calculateOzoneForUSDT(uint256 _usdtAmount) external view returns (
        uint256 ozoneAmount,
        uint256 currentPrice,
        uint256 poolId
    ) {
        currentPrice = getCurrentPrice();
        ozoneAmount = (_usdtAmount * 10**18) / currentPrice;
        
        if (_usdtAmount >= minPurchaseUSDT) {
            poolId = stakingContract.determinePoolByUSDTValue(_usdtAmount);
        }
        
        return (ozoneAmount, currentPrice, poolId);
    }
    
    /**
     * @dev Get user purchase history
     */
    function getUserPurchases(address _user) external view returns (UserPurchase[] memory) {
        return userPurchases[_user];
    }
    
    /**
     * @dev Get user purchase count
     */
    function getUserPurchaseCount(address _user) external view returns (uint256) {
        return userPurchases[_user].length;
    }
    
    /**
     * @dev Get user total stats
     */
    function getUserStats(address _user) external view returns (
        uint256 totalSpent,
        uint256 totalReceived,
        uint256 purchaseCount,
        uint256 averagePrice
    ) {
        totalSpent = totalUSDTSpent[_user];
        totalReceived = totalOZONEReceived[_user];
        purchaseCount = userPurchases[_user].length;
        
        if (totalReceived > 0) {
            // Calculate average price: totalSpent / totalReceived
            averagePrice = (totalSpent * 10**18) / totalReceived;
        }
        
        return (totalSpent, totalReceived, purchaseCount, averagePrice);
    }
    
    /**
     * @dev Get presale statistics
     */
    function getPresaleStats() external view returns (
        uint256 totalRaised,
        uint256 totalSold,
        uint256 totalBuyers,
        uint256 totalTxs,
        uint256 currentPrice,
        uint256 remaining,
        uint256 soldPercent
    ) {
        totalRaised = totalUSDTRaised;
        totalSold = totalOZONESold;
        totalBuyers = uniqueBuyers;
        totalTxs = totalPurchases;
        currentPrice = getCurrentPrice();
        remaining = remainingSupply;
        
        if (presaleSupply > 0) {
            soldPercent = ((presaleSupply - remainingSupply) * 100) / presaleSupply;
        }
        
        return (totalRaised, totalSold, totalBuyers, totalTxs, currentPrice, remaining, soldPercent);
    }
    
    /**
     * @dev Get price info
     */
    function getPriceInfo() external view returns (
        PriceSource source,
        uint256 currentPrice,
        uint256 lastUpdate,
        uint256 minPrice,
        uint256 maxPrice,
        bool isPriceStale
    ) {
        source = priceSource;
        currentPrice = getCurrentPrice();
        lastUpdate = lastPriceUpdate;
        minPrice = minAllowedPrice;
        maxPrice = maxAllowedPrice;
        
        isPriceStale = (source == PriceSource.MANUAL && 
                        block.timestamp - lastPriceUpdate > MAX_PRICE_AGE);
        
        return (source, currentPrice, lastUpdate, minPrice, maxPrice, isPriceStale);
    }
    
    /**
     * @dev Get contract version
     */
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }
    
    /**
     * @dev Check if purchase is valid
     */
    function validatePurchase(uint256 _usdtAmount) external view returns (
        bool isValid,
        string memory reason,
        uint256 ozoneAmount,
        uint256 poolId
    ) {
        if (_usdtAmount < minPurchaseUSDT) {
            return (false, "Below minimum purchase", 0, 0);
        }
        
        if (maxPurchaseUSDT > 0 && _usdtAmount > maxPurchaseUSDT) {
            return (false, "Above maximum purchase", 0, 0);
        }
        
        uint256 currentPrice = getCurrentPrice();
        if (currentPrice == 0) {
            return (false, "Invalid price", 0, 0);
        }
        
        ozoneAmount = (_usdtAmount * 10**18) / currentPrice;
        if (ozoneAmount == 0) {
            return (false, "Amount too small", 0, 0);
        }
        
        if (ozoneAmount > remainingSupply) {
            return (false, "Exceeds remaining supply", 0, 0);
        }
        
        poolId = stakingContract.determinePoolByUSDTValue(_usdtAmount);
        
        return (true, "Valid purchase", ozoneAmount, poolId);
    }
    
    // =============================================================================
    // UPGRADE AUTHORIZATION
    // =============================================================================
    
    /**
     * @dev Function that authorizes an upgrade to a new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        emit ContractUpgraded(newImplementation, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 ██████╗ ███████╗ ██████╗ ███╗   ██╗███████╗
██╔═══██╗╚══███╔╝██╔═══██╗████╗  ██║██╔════╝
██║   ██║  ███╔╝ ██║   ██║██╔██╗ ██║█████╗  
██║   ██║ ███╔╝  ██║   ██║██║╚██╗██║██╔══╝  
╚██████╔╝███████╗╚██████╔╝██║ ╚████║███████╗
 ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    🏭 OZONE RWA PRESALE - Tokenized Nickel Mining Investment
    
    ════════════════════════════════════════════════════════════════════
    │  🌏 Real World Asset: Indonesian Nickel Ore Mining Operations    │
    │  💳 Payment Method: USDT BEP-20 Only                             │
    │  📈 Purchase Tax: 1% (Mining Operations Fund)                    │
    │  🎯 Presale Phases: 4 Stages ($0.80 - $0.95)                     │
    │  ⛏️  Mining Sites: Konawe & Kolaka, Sulawesi Island              │     
    ════════════════════════════════════════════════════════════════════
    
    💡 Invest in real Indonesian nickel mining operations through 
       blockchain tokenization. Access the growing $2T RWA market.
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract OZONEPresale is Ownable, Pausable, ReentrancyGuard {
    IERC20 public immutable ozoneToken;
    IERC20 public immutable usdtToken; // USDT BEP-20 token
    
    struct PresalePhase {
        uint256 startTime;
        uint256 endTime;
        uint256 pricePerToken; // Price in USDT (6 decimals) per OZONE token (18 decimals)
        uint256 tokensAvailable;
        uint256 tokensSold;
        bool isActive;
    }
    
    PresalePhase[] public presalePhases;
    
    // User purchase tracking
    mapping(address => uint256) public userPurchases;
    mapping(address => bool) public isWhitelisted;
    
    // Configuration
    uint256 public minPurchase = 100 * 10**18; // 100 OZONE minimum
    uint256 public maxPurchase = 100000 * 10**18; // 100,000 OZONE maximum per user
    uint256 public constant PURCHASE_TAX_RATE = 100; // 1% = 100 basis points
    uint256 public constant BASIS_POINTS = 10000;
    
    address public treasuryWallet;
    address public taxWallet; // Separate wallet for purchase tax
    
    // Events
    event TokensPurchased(address indexed buyer, uint256 ozoneAmount, uint256 usdtCost, uint256 taxAmount, uint256 phase);
    event PresalePhaseAdded(uint256 indexed phaseId, uint256 startTime, uint256 endTime, uint256 price);
    event PresalePhaseUpdated(uint256 indexed phaseId, bool isActive);
    event TokensWithdrawn(address indexed to, uint256 amount);
    event USDTWithdrawn(address indexed to, uint256 amount);
    event TaxWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event PurchaseTaxCollected(address indexed buyer, uint256 taxAmount);
    
    constructor(
        address _ozoneToken,
        address _usdtToken,
        address _treasuryWallet,
        address _taxWallet
    ) Ownable(msg.sender) {
        require(_ozoneToken != address(0), "Invalid OZONE token address");
        require(_usdtToken != address(0), "Invalid USDT token address");
        require(_treasuryWallet != address(0), "Invalid treasury address");
        require(_taxWallet != address(0), "Invalid tax wallet address");
        
        ozoneToken = IERC20(_ozoneToken);
        usdtToken = IERC20(_usdtToken);
        treasuryWallet = _treasuryWallet;
        taxWallet = _taxWallet;
        
        // Initialize presale phases (will be configured via admin)
        _initializePresalePhases();
    }
    
    function _initializePresalePhases() internal {
        // Initialize empty - will be configured via admin dashboard
        // This allows full flexibility for configuration
    }
    
    function buyTokens(uint256 usdtAmount) external nonReentrant whenNotPaused {
        require(usdtAmount > 0, "Must specify USDT amount");
        // Whitelist requirement REMOVED for better UX
        // require(isWhitelisted[msg.sender], "Not whitelisted");
        
        uint256 currentPhase = getCurrentPhase();
        require(currentPhase < presalePhases.length, "No active presale phase");
        
        PresalePhase storage phase = presalePhases[currentPhase];
        require(phase.isActive, "Phase not active");
        require(block.timestamp >= phase.startTime && block.timestamp <= phase.endTime, "Phase not in timeline");
        
        // Calculate tokens to buy based on USDT amount
        // USDT has 6 decimals, OZONE has 18 decimals
        // Price is stored as USDT (6 decimals) per OZONE token
        // Fixed formula: Remove extra 10**12 division that was causing calculation error
        uint256 tokensToBuy = (usdtAmount * 10**18) / phase.pricePerToken;
        
        // Calculate total cost including 1% purchase tax
        uint256 taxAmount = (usdtAmount * PURCHASE_TAX_RATE) / BASIS_POINTS; // 1% tax
        uint256 totalCost = usdtAmount + taxAmount; // Base price + tax
        
        // Validate purchase limits
        require(tokensToBuy >= minPurchase, "Below minimum purchase");
        require(userPurchases[msg.sender] + tokensToBuy <= maxPurchase, "Exceeds maximum purchase");
        require(phase.tokensSold + tokensToBuy <= phase.tokensAvailable, "Exceeds phase allocation");
        
        // Check user's USDT balance and allowance for total cost (including tax)
        require(usdtToken.balanceOf(msg.sender) >= totalCost, "Insufficient USDT balance");
        require(usdtToken.allowance(msg.sender, address(this)) >= totalCost, "Insufficient USDT allowance");
        
        // Update state
        phase.tokensSold += tokensToBuy;
        userPurchases[msg.sender] += tokensToBuy;
        
        // Transfer USDT: base price to treasury, tax to tax wallet
        require(usdtToken.transferFrom(msg.sender, treasuryWallet, usdtAmount), "Base USDT transfer failed");
        require(usdtToken.transferFrom(msg.sender, taxWallet, taxAmount), "Tax USDT transfer failed");
        
        // Transfer OZONE tokens to buyer
        require(ozoneToken.transfer(msg.sender, tokensToBuy), "OZONE transfer failed");
        
        emit TokensPurchased(msg.sender, tokensToBuy, usdtAmount, taxAmount, currentPhase);
        emit PurchaseTaxCollected(msg.sender, taxAmount);
    }
    
    function getCurrentPhase() public view returns (uint256) {
        for (uint256 i = 0; i < presalePhases.length; i++) {
            if (presalePhases[i].isActive && 
                block.timestamp >= presalePhases[i].startTime && 
                block.timestamp <= presalePhases[i].endTime) {
                return i;
            }
        }
        return presalePhases.length; // No active phase
    }
    
    function getPhaseInfo(uint256 phaseId) external view returns (PresalePhase memory) {
        require(phaseId < presalePhases.length, "Invalid phase ID");
        return presalePhases[phaseId];
    }
    
    function getAllPhases() external view returns (PresalePhase[] memory) {
        return presalePhases;
    }
    
    // Admin functions for flexible configuration
    function addPresalePhase(
        uint256 startTime,
        uint256 endTime,
        uint256 pricePerTokenUSDT, // Price in USDT (6 decimals, e.g., 800000 = $0.80)
        uint256 tokensAvailable
    ) external onlyOwner {
        require(startTime < endTime, "Invalid time range");
        require(pricePerTokenUSDT > 0, "Price must be positive");
        require(tokensAvailable > 0, "Tokens must be positive");
        
        presalePhases.push(PresalePhase({
            startTime: startTime,
            endTime: endTime,
            pricePerToken: pricePerTokenUSDT,
            tokensAvailable: tokensAvailable,
            tokensSold: 0,
            isActive: true
        }));
        
        uint256 phaseId = presalePhases.length - 1;
        emit PresalePhaseAdded(phaseId, startTime, endTime, pricePerTokenUSDT);
    }
    
    function updatePresalePhase(
        uint256 phaseId,
        uint256 startTime,
        uint256 endTime,
        uint256 pricePerTokenUSDT, // Price in USDT (6 decimals)
        uint256 tokensAvailable,
        bool isActive
    ) external onlyOwner {
        require(phaseId < presalePhases.length, "Invalid phase ID");
        require(startTime < endTime, "Invalid time range");
        require(pricePerTokenUSDT > 0, "Price must be positive");
        require(tokensAvailable >= presalePhases[phaseId].tokensSold, "Cannot reduce below sold amount");
        
        PresalePhase storage phase = presalePhases[phaseId];
        phase.startTime = startTime;
        phase.endTime = endTime;
        phase.pricePerToken = pricePerTokenUSDT;
        phase.tokensAvailable = tokensAvailable;
        phase.isActive = isActive;
        
        emit PresalePhaseUpdated(phaseId, isActive);
    }
    
    function removePresalePhase(uint256 phaseId) external onlyOwner {
        require(phaseId < presalePhases.length, "Invalid phase ID");
        require(presalePhases[phaseId].tokensSold == 0, "Cannot remove phase with sales");
        
        // Move last element to deleted spot and remove last element
        presalePhases[phaseId] = presalePhases[presalePhases.length - 1];
        presalePhases.pop();
    }
    
    function bulkConfigurePresale(
        uint256[] calldata startTimes,
        uint256[] calldata endTimes,
        uint256[] calldata prices,
        uint256[] calldata allocations
    ) external onlyOwner {
        require(startTimes.length == endTimes.length, "Array length mismatch");
        require(startTimes.length == prices.length, "Array length mismatch");
        require(startTimes.length == allocations.length, "Array length mismatch");
        
        // Clear existing phases (only if no sales yet)
        for (uint256 i = 0; i < presalePhases.length; i++) {
            require(presalePhases[i].tokensSold == 0, "Cannot reconfigure with existing sales");
        }
        delete presalePhases;
        
        // Add new phases
        for (uint256 i = 0; i < startTimes.length; i++) {
            require(startTimes[i] < endTimes[i], "Invalid time range");
            require(prices[i] > 0, "Price must be positive");
            require(allocations[i] > 0, "Allocation must be positive");
            
            presalePhases.push(PresalePhase({
                startTime: startTimes[i],
                endTime: endTimes[i],
                pricePerToken: prices[i],
                tokensAvailable: allocations[i],
                tokensSold: 0,
                isActive: true
            }));
            
            emit PresalePhaseAdded(i, startTimes[i], endTimes[i], prices[i]);
        }
    }

    function addToWhitelist(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            isWhitelisted[users[i]] = true;
        }
    }
    
    function removeFromWhitelist(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            isWhitelisted[users[i]] = false;
        }
    }
    
    function updatePhaseStatus(uint256 phaseId, bool isActive) external onlyOwner {
        require(phaseId < presalePhases.length, "Invalid phase ID");
        presalePhases[phaseId].isActive = isActive;
        emit PresalePhaseUpdated(phaseId, isActive);
    }
    
    function updatePurchaseLimits(uint256 _minPurchase, uint256 _maxPurchase) external onlyOwner {
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }
    
    function updateTreasuryWallet(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid treasury address");
        treasuryWallet = _newTreasury;
    }
    
    function updateTaxWallet(address _newTaxWallet) external onlyOwner {
        require(_newTaxWallet != address(0), "Invalid tax wallet address");
        address oldTaxWallet = taxWallet;
        taxWallet = _newTaxWallet;
        emit TaxWalletUpdated(oldTaxWallet, _newTaxWallet);
    }
    
    // Emergency functions
    function emergencyWithdrawTokens(uint256 amount) external onlyOwner {
        require(ozoneToken.transfer(owner(), amount), "Token transfer failed");
        emit TokensWithdrawn(owner(), amount);
    }
    
    function emergencyWithdrawUSDT() external onlyOwner {
        uint256 balance = usdtToken.balanceOf(address(this));
        require(usdtToken.transfer(owner(), balance), "USDT transfer failed");
        emit USDTWithdrawn(owner(), balance);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // View functions for frontend and admin dashboard
    function calculateTokensForUSDT(uint256 usdtAmount) external view returns (uint256 tokens, uint256 currentPhase) {
        currentPhase = getCurrentPhase();
        if (currentPhase >= presalePhases.length) {
            return (0, currentPhase);
        }
        
        // USDT has 6 decimals, OZONE has 18 decimals
        // Fixed formula: Remove extra 10**12 multiplication
        tokens = (usdtAmount * 10**18) / presalePhases[currentPhase].pricePerToken;
        return (tokens, currentPhase);
    }
    
    function calculateUSDTForTokens(uint256 tokenAmount) external view returns (uint256 usdtCost, uint256 currentPhase) {
        currentPhase = getCurrentPhase();
        if (currentPhase >= presalePhases.length) {
            return (0, currentPhase);
        }
        
        // Calculate USDT cost for given token amount
        // Fixed formula: Remove extra 10**12 multiplication
        usdtCost = (tokenAmount * presalePhases[currentPhase].pricePerToken) / 10**18;
        return (usdtCost, currentPhase);
    }
    
    function getUserPurchaseInfo(address user) external view returns (uint256 purchased, uint256 remaining) {
        purchased = userPurchases[user];
        remaining = maxPurchase - purchased;
        return (purchased, remaining);
    }
    
    function getPresaleOverview() external view returns (
        uint256 totalPhases,
        uint256 totalTokensAllocated,
        uint256 totalTokensSold,
        uint256 totalETHRaised,
        uint256 currentActivePhase
    ) {
        totalPhases = presalePhases.length;
        currentActivePhase = getCurrentPhase();
        
        for (uint256 i = 0; i < presalePhases.length; i++) {
            totalTokensAllocated += presalePhases[i].tokensAvailable;
            totalTokensSold += presalePhases[i].tokensSold;
            // Calculate USDT raised (convert from 18 decimals to 6 decimals)
            // Fixed formula: Remove extra 10**12 multiplication
            totalETHRaised += (presalePhases[i].tokensSold * presalePhases[i].pricePerToken) / 10**12;
        }
        
        return (totalPhases, totalTokensAllocated, totalTokensSold, totalETHRaised, currentActivePhase); // totalETHRaised is actually USDT raised
    }
    
    function getPhaseProgress(uint256 phaseId) external view returns (
        uint256 tokensSold,
        uint256 tokensRemaining,
        uint256 progressPercentage,
        uint256 usdtRaised
    ) {
        require(phaseId < presalePhases.length, "Invalid phase ID");
        
        PresalePhase memory phase = presalePhases[phaseId];
        tokensSold = phase.tokensSold;
        tokensRemaining = phase.tokensAvailable - phase.tokensSold;
        progressPercentage = phase.tokensAvailable > 0 ? (tokensSold * 100) / phase.tokensAvailable : 0;
        // Calculate USDT raised for this phase (convert from 18 decimals to 6 decimals)
        // Fixed formula: Remove extra 10**12 multiplication
        usdtRaised = (tokensSold * phase.pricePerToken) / 10**12;
        
        return (tokensSold, tokensRemaining, progressPercentage, usdtRaised);
    }
    
    function getTimeRemaining(uint256 phaseId) external view returns (uint256 timeLeft, bool isActive) {
        require(phaseId < presalePhases.length, "Invalid phase ID");
        
        PresalePhase memory phase = presalePhases[phaseId];
        isActive = phase.isActive && block.timestamp >= phase.startTime && block.timestamp <= phase.endTime;
        
        if (block.timestamp >= phase.endTime) {
            timeLeft = 0;
        } else if (block.timestamp < phase.startTime) {
            timeLeft = phase.startTime - block.timestamp;
        } else {
            timeLeft = phase.endTime - block.timestamp;
        }
        
        return (timeLeft, isActive);
    }
    
    function getAllUserPurchases() external view onlyOwner returns (address[] memory users, uint256[] memory amounts) {
        // Note: This would be expensive on-chain. Better to use events for off-chain indexing
        // This is just for admin emergency use
        uint256 count = 0;
        
        // In a real implementation, you'd maintain an array of buyers
        // For now, this is a placeholder that shows the concept
        users = new address[](count);
        amounts = new uint256[](count);
        
        return (users, amounts);
    }
}
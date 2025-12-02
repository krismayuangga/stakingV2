// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 ▒█████  ▒███████▒ ▒█████   ███▄    █ ▓█████ 
▒██▒  ██▒▒ ▒ ▒ ▄▀░▒██▒  ██▒ ██ ▀█   █ ▓█   ▀ 
▒██░  ██▒░ ▒ ▄▀▒░ ▒██░  ██▒▓██  ▀█ ██▒▒███   
▒██   ██░  ▄▀▒   ░▒██   ██░▓██▒  ▐▌██▒▒▓█  ▄ 
░ ████▓▒░▒███████▒░ ████▓▒░▒██░   ▓██░░▒████▒
░ ▒░▒░▒░ ░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░░ ▒░ ░
  ░ ▒ ▒░ ░░▒ ▒ ░ ▒  ░ ▒ ▒░ ░ ░░   ░ ▒░ ░ ░  ░
░ ░ ░ ▒  ░ ░ ░ ░ ░░ ░ ░ ▒     ░   ░ ░    ░   
    ░ ░    ░ ░        ░ ░           ░    ░  ░
         ░
                                              
    ⛏️ OZONE RWA TOKEN - Real World Asset Mining Protocol ⛏️
    🏭 Tokenized Nickel Mining | Sulawesi Island, Indonesia
    
    ════════════════════════════════════════════════════════════════════
    │  🌏 Real World Assets: Nickel Ore Mining Operations              │
    │  🏭 Mining Sites: Konawe & Kolaka, Sulawesi Island               │  
    │  📊 Production: 50,000-80,000 WMT per week                       │
    │  🪙 Total Supply: 1,000,000,000 OZONE Tokens                     │
    │  💰 Transfer Tax: 1% to Treasury (Mining Operations Fund)        │
    │  🔗 Backed By: Physical Nickel Ore Trading & Shipments           │
    ════════════════════════════════════════════════════════════════════
    
    💡 OZONE represents real-time nickel ore being traded from 
       Indonesian mining sites through blockchain tokenization.
       Investing offers exclusive access to the $2T RWA market by 2030.
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OZONE is ERC20, Ownable, Pausable {
    uint256 public constant TAX_RATE = 100; // 1% = 100 basis points
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18; // Fixed 1 billion tokens
    
    address public treasuryWallet;
    
    mapping(address => bool) public isExemptFromTax;
    mapping(address => bool) public isCEXAddress;
    mapping(address => bool) public isDEXAddress;
    mapping(address => bool) public authorizedBurners;
    
    // RWA Features - Proof of Reserves Tracking
    uint256 public monthlyProfitUSDT;
    uint256 public totalDistributedRewards;
    uint256 public currentNickelPriceUSDT; // Price per kg in USDT (6 decimals)
    
    // Events
    event TaxCollected(address indexed from, address indexed to, uint256 taxAmount);
    event TreasuryWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event TaxExemptionUpdated(address indexed account, bool isExempt);
    event CEXAddressUpdated(address indexed account, bool isCEX);
    event DEXAddressUpdated(address indexed account, bool isDEX);
    event TokensBurned(address indexed burner, uint256 amount);
    event AuthorizedBurnerUpdated(address indexed burner, bool authorized);
    event ProfitUpdated(uint256 monthlyProfit, uint256 timestamp);
    event NickelPriceUpdated(uint256 newPrice, uint256 timestamp);
    
    constructor(
        address _treasuryWallet
    ) ERC20("OZONE", "OZONE") Ownable(msg.sender) {
        require(_treasuryWallet != address(0), "Treasury wallet cannot be zero");
        
        treasuryWallet = _treasuryWallet;
        
        // Mint fixed total supply to owner (no more minting allowed after this)
        _mint(msg.sender, TOTAL_SUPPLY);
        
        // Exempt treasury and owner from tax
        isExemptFromTax[_treasuryWallet] = true;
        isExemptFromTax[msg.sender] = true;
    }
    
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        _transferWithTax(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferWithTax(from, to, amount);
        return true;
    }
    
    function _transferWithTax(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        
        // No tax scenarios:
        // 1. Exempt addresses (treasury, presale contract, etc)
        // 2. CEX addresses (Binance, Coinbase, etc)
        // 3. Contract itself
        if (isExemptFromTax[from] || isExemptFromTax[to] || 
            isCEXAddress[from] || isCEXAddress[to] || 
            from == address(this) || to == address(this)) {
            // No tax for exempt/CEX addresses
            _transfer(from, to, amount);
        } else {
            // Apply 1% tax for:
            // - DEX trading (PancakeSwap, etc)
            // - P2P transfers
            // - Any other non-exempt transfers
            uint256 taxAmount = (amount * TAX_RATE) / BASIS_POINTS;
            uint256 transferAmount = amount - taxAmount;
            
            // Transfer tax to treasury
            if (taxAmount > 0) {
                _transfer(from, treasuryWallet, taxAmount);
                emit TaxCollected(from, to, taxAmount);
            }
            
            // Transfer remaining amount
            _transfer(from, to, transferAmount);
        }
    }
    
    // Admin functions
    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(_newTreasuryWallet != address(0), "Treasury wallet cannot be zero");
        address oldWallet = treasuryWallet;
        treasuryWallet = _newTreasuryWallet;
        
        // Update tax exemption
        isExemptFromTax[oldWallet] = false;
        isExemptFromTax[_newTreasuryWallet] = true;
        
        emit TreasuryWalletUpdated(oldWallet, _newTreasuryWallet);
    }
    
    function setTaxExemption(address account, bool exempt) external onlyOwner {
        isExemptFromTax[account] = exempt;
        emit TaxExemptionUpdated(account, exempt);
    }
    
    // CEX Management (Binance, Coinbase, etc) - NO TAX
    function setCEXAddress(address account, bool isCEX) external onlyOwner {
        isCEXAddress[account] = isCEX;
        emit CEXAddressUpdated(account, isCEX);
    }
    
    function bulkSetCEXAddresses(address[] calldata accounts, bool isCEX) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isCEXAddress[accounts[i]] = isCEX;
            emit CEXAddressUpdated(accounts[i], isCEX);
        }
    }
    
    // DEX Management (PancakeSwap, etc) - WITH TAX  
    function setDEXAddress(address account, bool isDEX) external onlyOwner {
        isDEXAddress[account] = isDEX;
        emit DEXAddressUpdated(account, isDEX);
    }
    
    function bulkSetDEXAddresses(address[] calldata accounts, bool isDEX) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isDEXAddress[accounts[i]] = isDEX;
            emit DEXAddressUpdated(accounts[i], isDEX);
        }
    }
    
    // NOTE: No mint function - Total supply is FIXED at 1 billion OZONE tokens
    // This ensures controlled tokenomics and prevents inflation
    
    // Burn mechanism for staking contract
    function burn(uint256 amount) external {
        require(authorizedBurners[msg.sender], "Not authorized to burn");
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    function setAuthorizedBurner(address burner, bool authorized) external onlyOwner {
        authorizedBurners[burner] = authorized;
        emit AuthorizedBurnerUpdated(burner, authorized);
    }
    
    // RWA Management Functions
    function updateMonthlyProfit(uint256 _profitUSDT) external onlyOwner {
        monthlyProfitUSDT = _profitUSDT;
        emit ProfitUpdated(_profitUSDT, block.timestamp);
    }
    
    function updateNickelPrice(uint256 _priceUSDT) external onlyOwner {
        currentNickelPriceUSDT = _priceUSDT;
        emit NickelPriceUpdated(_priceUSDT, block.timestamp);
    }
    
    function addToDistributedRewards(uint256 _amount) external {
        require(authorizedBurners[msg.sender], "Not authorized");
        totalDistributedRewards += _amount;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Emergency functions
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).transfer(owner(), amount);
        }
    }
    
    // View functions
    function calculateTax(uint256 amount) external pure returns (uint256) {
        return (amount * TAX_RATE) / BASIS_POINTS;
    }
    
    function getTransferAmount(uint256 amount, address from, address to) external view returns (uint256 transferAmount, uint256 taxAmount) {
        if (isExemptFromTax[from] || isExemptFromTax[to]) {
            return (amount, 0);
        }
        
        taxAmount = (amount * TAX_RATE) / BASIS_POINTS;
        transferAmount = amount - taxAmount;
        
        return (transferAmount, taxAmount);
    }
    
    function getFixedTotalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }
    
    // Note: This function always returns 0 since total supply is fixed and fully minted
    // Kept for interface compatibility but marked as deprecated
    function getRemainingSupply() external pure returns (uint256) {
        return 0; // All tokens are already minted (fixed supply model)
    }
    
    // Enhanced view functions for future integrations
    function getAddressType(address account) external view returns (string memory) {
        if (isExemptFromTax[account]) return "EXEMPT";
        if (isCEXAddress[account]) return "CEX";
        if (isDEXAddress[account]) return "DEX";
        return "REGULAR";
    }
    
    function willHaveTax(address from, address to) external view returns (bool, uint256) {
        if (isExemptFromTax[from] || isExemptFromTax[to] || 
            isCEXAddress[from] || isCEXAddress[to] || 
            from == address(this) || to == address(this)) {
            return (false, 0);
        }
        return (true, TAX_RATE);
    }
    
    // RWA View Functions
    function getRWAStats() external view returns (
        uint256 monthlyProfit,
        uint256 totalRewardsDistributed,
        uint256 nickelPrice,
        uint256 totalSupply_,
        uint256 burnedSupply
    ) {
        return (
            monthlyProfitUSDT,
            totalDistributedRewards,
            currentNickelPriceUSDT,
            totalSupply(),
            TOTAL_SUPPLY - totalSupply()
        );
    }
    
    function getProofOfReserves() external view returns (
        uint256 treasuryBalance,
        uint256 monthlyProfit,
        uint256 distributedRewards,
        uint256 availableForRewards
    ) {
        return (
            address(treasuryWallet).balance,
            monthlyProfitUSDT,
            totalDistributedRewards,
            monthlyProfitUSDT > totalDistributedRewards ? monthlyProfitUSDT - totalDistributedRewards : 0
        );
    }
}
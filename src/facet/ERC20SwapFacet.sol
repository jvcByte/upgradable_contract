// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibERC20} from "../libraries/LibERC20.sol";

interface IAggregatorV3Interface {
    function latestRoundData() external view returns(
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    );
}

/**
 * @title ERC20SwapFacet
 * @notice Facet for swapping ETH to ERC20 tokens using Chainlink price feeds
 * @dev Part of Diamond Standard (EIP-2535) implementation
 */
contract ERC20SwapFacet {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TokensSwapped(address indexed buyer, uint256 ethAmount, uint256 tokenAmount, uint256 ethPrice);
    
    // Chainlink ETH/USD price feed (Sepolia)
    IAggregatorV3Interface public constant ETH_USD_FEED = IAggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    
    // Token price in USD (18 decimals): $0.01 per token
    uint256 public constant TOKEN_PRICE_USD = 0.01e18;
    
    // Maximum price feed age (1 hour)
    uint256 public constant MAX_PRICE_AGE = 3600;
    
    // Minimum ETH amount to prevent dust
    uint256 public constant MIN_ETH_AMOUNT = 0.001 ether;
    
    error InvalidAmount();
    error InvalidSender();
    error StalePriceFeed();
    error InvalidPriceFeed();
    
    /**
     * @notice Swap ETH for tokens based on Chainlink ETH/USD price
     * @dev Mints tokens directly to msg.sender. ETH stays in diamond contract.
     */
    function swap() external payable {
        if (msg.value < MIN_ETH_AMOUNT) revert InvalidAmount();
        if (msg.sender == address(0)) revert InvalidSender();
        
        // Get validated ETH price
        uint256 ethPrice = _getValidatedEthPrice();
        
        // Calculate tokens to mint
        uint256 tokensToMint = _calculateTokenAmount(msg.value, ethPrice);
        
        // Update ERC20 storage via library
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        es.totalSupply += tokensToMint;
        es.balances[msg.sender] += tokensToMint;
        
        emit Transfer(address(0), msg.sender, tokensToMint);
        emit TokensSwapped(msg.sender, msg.value, tokensToMint, ethPrice);
    }
    
    /**
     * @notice Get current ETH price from Chainlink oracle
     * @return ethPrice ETH price in USD with 8 decimals
     */
    function getEthPrice() external view returns (uint256 ethPrice) {
        return _getValidatedEthPrice();
    }
    
    /**
     * @notice Calculate token amount for given ETH input
     * @param ethAmount Amount of ETH in wei
     * @return tokenAmount Amount of tokens with 18 decimals
     */
    function calculateTokens(uint256 ethAmount) external view returns (uint256 tokenAmount) {
        if (ethAmount == 0) return 0;
        uint256 ethPrice = _getValidatedEthPrice();
        return _calculateTokenAmount(ethAmount, ethPrice);
    }
    
    /**
     * @notice Get diamond's ETH balance
     * @return balance ETH balance in wei
     */
    function getContractBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }
    
    /**
     * @dev Internal function to get and validate Chainlink price feed
     * @return ethPrice Validated ETH price with 8 decimals
     */
    function _getValidatedEthPrice() internal view returns (uint256 ethPrice) {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = ETH_USD_FEED.latestRoundData();
        
        // Comprehensive price feed validation
        if (answer <= 0) revert InvalidPriceFeed();
        if (updatedAt == 0) revert InvalidPriceFeed();
        if (answeredInRound < roundId) revert InvalidPriceFeed();
        if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePriceFeed();
        
        return uint256(answer);
    }
    
    /**
     * @dev Internal function to calculate token amount from ETH
     * @param ethAmount ETH amount in wei (18 decimals)
     * @param ethPrice ETH price in USD with 8 decimals
     * @return tokenAmount Token amount with 18 decimals
     */
    function _calculateTokenAmount(uint256 ethAmount, uint256 ethPrice) 
        internal 
        pure 
        returns (uint256 tokenAmount) 
    {
        // Calculate ETH value in USD (18 decimals)
        // (wei * price_8_decimals) / 1e8 = USD_18_decimals
        uint256 ethValueUSD = (ethAmount * ethPrice) / 1e8;
        
        // Calculate tokens: USD_value / token_price
        // (USD_18_decimals * 1e18) / TOKEN_PRICE_USD_18_decimals = tokens_18_decimals
        return (ethValueUSD * 1e18) / TOKEN_PRICE_USD;
    }
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './SeedCore.sol';
import '../interface/ISeedCoreTransfers.sol';

/**

    SeedCoreTransfers enforces limit-Based transfer restrictions.

 */

contract SeedCoreTransfers is SeedCore, ISeedCoreTransfers  {

    ////////////////
    // STATES
    ////////////////

    /**
     * Mapping from token ID to the limit on the amount of Shareholders for this token, when transfering 
     * between holders.
     */
    mapping(uint256 => uint256) public _ShareholderLimitByToken;
    
    /**
     * Mapping from token ID to minimum Share holding, transfers that result in holdings that fall bellow 
     * the mininmum will fail.
     */
    mapping(uint256 => uint256) public _ShareholdingMinimumByToken;
    
    /**
     * Mapping from token ID to non-divisible bool, transfers that result in divisible holdings will fail.
     */
    mapping(uint256 => bool) public _ShareholdingNonDivisibleByToken;

    ////////////////
    // MODIFIERS
    ////////////////
    
    /**
     * @dev Ensures that the new Shareholder limit is not less than the current amount of Shareholders.
     * @param holderLimit The maximum number of Shareholders per token ID.
     * @param tokenId The token to enforce the holder limit on.
     */
    modifier notLessThanHolders(
        uint256 tokenId,
        uint256 holderLimit
    ) {
        if (holderLimit < _ShareholdersByToken[tokenId].length)
            revert LimitLessThanCurrentShareholders();
        _;
    }
    
    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    /**
     * @dev Bundles all the setters needed for token configuration into a single function for token creation.
     * @param tokenId The token ID of the newly created token.
     * @param ShareholderLimit The maximum number of Shareholders for the newly created token.
     * @param ShareholdingMinimum The minimum amount of Shares per Shareholder for the token.
     * @param ShareholdingNonDivisible boolean as to if Share transfers can result in fractional Shares. 
     */
    function createToken(
        uint256 tokenId,
        uint256 ShareholderLimit,
        uint256 ShareholdingMinimum,
        bool ShareholdingNonDivisible
    )
        public
    {
        setShareholderLimit(tokenId, ShareholderLimit);   
        setShareholdingMinimum(tokenId, ShareholdingMinimum);
        setNonDivisible(tokenId, ShareholdingNonDivisible);
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    /**
     * @dev Returns boolean as to if a batch of transfers are viable and do not violate any transfer limits.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenIds An array of token IDs for the tokens to transfer.
     * @param amounts An array of integer amounts for each of the token IDs in the token transfer.
     */
    function checkCanTransferBatch(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    )
        public 
        view 
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++)
            checkCanTransfer(from, to, tokenIds[i], amounts[i]);
    
        return true;
    }
    
    /**
     * @dev Returns boolean as to if a transfer is viable and does not violate any transfer limits.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer.
     */
    function checkCanTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)
    {
        if (!checkWithinShareholderLimit(tokenId))
            revert ExceedsMaximumShareholders();

        if (!checkAboveMinimumShareholdingTransfer(from, to, tokenId, amount))
            revert BelowMinimumShareholding();

        if (!checkAmountNonDivisibleTransfer(from, to, tokenId, amount))
            revert ShareDivision();

        return true;
    }

    /**
     * @dev Returns boolean as to if the transfer does not create an amount of Shareholders that exceeds
     * the Shareholder limit.
     *
     * @param tokenId Token ID to check the Shareholder limit against.
     */
    function checkWithinShareholderLimit(
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        if (_ShareholderLimitByToken[tokenId] < _ShareholdersByToken[tokenId].length + 1)
            return true;
        else 
            return false;
    }

    /**
     * @dev Returns boolean as to if the transfer does not result in Shareholdings that fall below the minimum
     * Shareholding per investor for the Share type. 
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer
     */
    function checkAboveMinimumShareholdingTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)
    {   
        // Standard transfer
        if (from != address(0) && to != address(0)) 
            if (checkAboveMinimumShareholding(tokenId, _Share.balanceOf(to, tokenId) - amount) && checkAboveMinimumShareholding(tokenId, _Share.balanceOf(from, tokenId) + amount))
                return true;    
        // Mint
        else if (from == address(0) && to != address(0))
            if (checkAboveMinimumShareholding(tokenId, _Share.balanceOf(to, tokenId) + amount))
                return true;
        // Burn
        else if (from != address(0) && to == address(0))
            if (checkAboveMinimumShareholding(tokenId, _Share.balanceOf(from, tokenId) - amount))
                return true;
                
        return false;
    }

    /**
     * @dev Returns boolean as to if the transfer does not result in non-divisible Shares if non-divisibility
     * is are enforced on the Share type.
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer
     */
    function checkAmountNonDivisibleTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)
    {   
        // If enforcing non-divisisibility
        if (_ShareholdingNonDivisibleByToken[tokenId]) {
            // Standard transfer
            if (from != address(0) && to != address(0)) 
                if (checkAmountNonDivisible(_Share.balanceOf(to, tokenId) - amount) && checkAmountNonDivisible(_Share.balanceOf(from, tokenId) + amount))
                    return true;
                else
                    return false;    
            // Mint
            else if (from == address(0) && to != address(0))
                if (checkAmountNonDivisible(_Share.balanceOf(to, tokenId) + amount))
                    return true;
                else
                    return false;
            // Burn
            else if (from != address(0) && to == address(0))
                if (checkAmountNonDivisible(_Share.balanceOf(from, tokenId) - amount))
                    return true;
                else
                    return false;
            else 
                return false;
        }
        else
            return true;   
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Sets the maximum Shareholder limit.
     * @param tokenId The token ID to set the holder limit on.
     * @param holderLimit The maximum number of Shareholders.
     */
    function setShareholderLimit(
        uint256 tokenId, 
        uint256 holderLimit
    )
        public
        notLessThanHolders(tokenId, holderLimit)
    {
        // Set holder limit
        _ShareholderLimitByToken[tokenId] = holderLimit;

        // Event
        emit ShareholderLimitSet(tokenId, holderLimit);
    }
    
    /**
     * @dev Sets the minimum Shareholding on transfers.
     * @param tokenId The token ID to set the minimum Shareholding on.
     * @param minimumAmount The minimum amount of Shares per Shareholder.
     */
    function setShareholdingMinimum(
        uint256 tokenId,
        uint256 minimumAmount
    )
        public
    {
        // Set minimum
        _ShareholdingMinimumByToken[tokenId] = minimumAmount;

        // Event
        emit MinimumShareholdingSet(tokenId, minimumAmount);
    }

    /** 
     * @dev Set transfers that are not modulus zero e18. WARNING! It is extremely hard to reverse once it has been set to false.
     * @param tokenId The token ID to set the divisibility status on.
     * @param nonDivisible The boolean as to if the Share type is divisible.
     */
    function setNonDivisible(
        uint256 tokenId,
        bool nonDivisible
    )
        public
    {
        // Set divisibleity
        _ShareholdingNonDivisibleByToken[tokenId] = nonDivisible;

        // Event
        emit NonDivisible(tokenId, nonDivisible);
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the Shareholder limit for investor transfers.
     * @param tokenId The token ID to query.
     */
    function getShareholderLimit(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _ShareholderLimitByToken[tokenId];
    }

    /**
     * @dev Returns the number of Shareholders by country.
     * @param tokenId The token ID to query.
     * @param country The country to return number of Shareholders for.
     */
    function getShareholderCountByCountry(
        uint256 tokenId,
        uint16 country
    )
        public
        view
        returns (uint256)
    {
        return _ShareholderCountbyCountryByToken[tokenId][country];
    }

    /**
     * @dev Returns the number of Shareholders.
     * @param tokenId The token ID to query.
     */
    function getShareholderCount(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _ShareholdersByToken[tokenId].length;
    }

    /**
     * @dev Returns the minimum Shareholding.
     * @param tokenId The token ID to query.
     */
    function getShareholdingMinimum(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _ShareholdingMinimumByToken[tokenId];
    }

}
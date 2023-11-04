// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inheriting
import '../interface/ISeedShare.sol';
import './SeedShareCoreManager.sol';
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

// Interfaces
import '../interface/ISeedCoreCompliance.sol';
import '../interface/ISeedCoreRegistry.sol';

/**

    SeedShare is an ERC1155 Based tokenised equity contract. It provides all the functions
    traditionally associated with an ERC1155 token contract, plus additional issuer controls
    designed (and legally required in some jurisdictions) to support for equity Shares. These
    features include forced transfers and Share recovery in the event that a Shareholder has 
    lost access to their wallet.

 */

contract SeedShare is ISeedShare, SeedShareCoreManager, ERC1155, Ownable {

    ////////////////
    // STATE
    ////////////////

    /**
     * @dev Total tokens, incremented value used to get the most recent/next token ID.
     */
    uint256 _totalTokens;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(string memory uri_) ERC1155(uri_) {}

    ////////////////
    // MODIFIERS
    ////////////////

    /**
     * @dev Prevents token transfers to the zero address.
     * @param to The receiving address.
     */
    modifier transferToZeroAddress(
        address to
    ) {
        if (to == address(0))
            revert TransferToZeroAddress();
        _;
    }

    /**
     * @dev Ensures the sender has sufficient tokens for a token transfer.
     * @param from The transfering address. 
     * @param id The id of the token transfer.
     * @param amount The amount of tokens to transfer.
     */
    modifier sufficientTokens(
        address from,
        uint256 id,
        uint256 amount
    ) {
        if (from != address(0))
            if (balanceOf(from, id) <= amount)
                revert InsufficientTokens();
        _;
    } 

    /**
     * @dev Ensures that the array of accounts and amounts are of equal length.
     * @param accounts An array of user addresses.
     * @param amounts An array of the integer amounts.
     */
    modifier equalAccountsAmounts(
        address[] memory accounts,
        uint256[] memory amounts
    ) {
        if (accounts.length != amounts.length)
            revert UnequalAccountsAmounts();
        _;
    }

    /**
     * @dev Ensures that mint amount is non-zero.
     * @param amount The amount of token transfer.
     */
    modifier mintZeroTokens(
        uint256 amount
    ) {
        if (amount == 0)
            revert MintZeroTokens();
        _;
    }

    //////////////////////////////////////////////
    // CREATE NEW TOKEN
    //////////////////////////////////////////////

    /** 
     * @dev Returns the total token count where token IDs are incremental values.
     */
    function getTotalTokens()
        public
        view 
        returns (uint256)
    {
        return _totalTokens;
    }

    /**
     * @dev Create a new token by incrementing token ID and initizializing in the compliance contracts.
     * @param 
     */
    function createToken(
        address[] memory SeedCores_,
        bytes[] memory SeedCoresData_
    )
        public
        onlyOwner
        returns (uint256)
    {
        // Ensure SeedCore array parity
        if (SeedCores_.length != SeedCoresData_.length)
            revert NoArrayParity();

        // Increment tokens
        _totalTokens++;
        
        // If has SeedCores
        /**
            if (SeedCores_.length != 0) {
                for (uint8 i = 0; i < SeedCores_.length; i++) {

                    // #TODO, this needs to be partioned Based on token id
                    
                    SeedCores[SeedCores_[i]] = true;

                    if (SeedCoresData_[i].length != 0) {
                        (bool success, ) = SeedCores_[i].call(SeedCoresData_[i]);

                        // If init failed 
                        if (!success)
                            revert InitCallFail();
                    }

                }
            }
        */

        // Event
        emit createToken(_totalTokens, ShareholderLimit, ShareholdingMinimum, ShareholdingNonDivisible);

        return _totalTokens;
    }

    //////////////////////////////////////////////
    // ISSUER CONTROLS
    //////////////////////////////////////////////

    /** 
     * @dev Owner-operator function to burn and reissue Shares in the event of a lost wallet.
     * @param lostWallet The address of the wallet that contains the Shares for reissue.
     * @param newWallet The address of the wallet that reissued Shares should be sent to.
     * @param data Optional data field to include in events.
    */
	function recover(
        address lostWallet,
        address newWallet,
        bytes memory data
    )
        external
        onlyOwner 
        returns (bool)
    {
        // For all tokens 
        for (uint8 id = 0; id < _totalTokens; id++)

            // If user has balance for tokens
            if (balanceOf(lostWallet, id) > 0)

                // Transfer tokens from old account to new one
                forcedTransferFrom(lostWallet, newWallet, id, balanceOf(lostWallet, id), data);
                
        
        // Event
        emit RecoverySuccess(lostWallet, newWallet);

        return true;
    }
	
    /** 
     * @dev Owner-operator function to force a batch transfer from an address. May be used to burn
     * and reissue if the Share terms are updated.
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param ids An array of token IDs for the token transfer.
     * @param amounts An array of integer amounts for each token in the token transfer.
     * @param data Optional data field to include in events.
     */
    function forcedBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		public
		virtual
		override 
		onlyOwner
	{
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /** 
     * @dev Owner-operator function used to force a transfer from an address. Typically used in the
     * case of Share recovery.
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param id The id of the token transfer.
     * @param amount The amount of tokens to transfer.
     * @param data Optional data field to include in events.
     */
	function forcedTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
	)
		public
		virtual
		override 
		onlyOwner
	{
		_safeTransferFrom(from, to, id, amount, data);
	}

    //////////////////////////////////////////////
    // MINT AND BURN 
    //////////////////////////////////////////////

    /**
     * @dev Mint Shares to a group of receiving addresses. 
     * @param accounts An array of the recieving accounts.
     * @param id The token ID to mint.
     * @param amounts An array of the amount to mint to each receiver.
     * @param data Optional data field to include in events.
     */
    function mintGroup(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyOwner
        equalAccountsAmounts(accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++)
            mint(accounts[i], id, amounts[i], data);
    }
    
    /**
     * @dev Mint Shares to a receiving address. 
     * @param account The receiving address.
     * @param id The token ID to mint.
     * @param amount The amount of Shares to mint to the receiver.
     * @param data Optional data field to include in events.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        onlyOwner
        transferToZeroAddress(account)
        mintZeroTokens(amount)
    {
        // Mint
        _mint(account, id, amount, data);

        // Event
        emit MintTokens(account, id, amount, data);
    }

    /**
     * @dev Burn Shares from a group of Shareholder addresses. 
     * @param accounts An array of the accounts to burn Shares from.
     * @param id The token ID to burn.
     * @param amounts An array of the amounts of Shares to burn from each account.
     * @param data Optional data field to include in events.
     */
    function burnGroup(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyOwner
        equalAccountsAmounts(accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            burn(accounts[i], id, amounts[i], data );
        }
    }

    /**
     * @dev Burn Shares from a Shareholder address. 
     * @param account The account Shares are being burnt from.
     * @param id The token ID to mint to receiver.
     * @param amount The amount of tokens to burn from the account.
     * @param data Optional data field to include in events.
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        onlyOwner
    {
        // Burn
        _burn(account, id, amount);

        // Event
        emit BurnTokens(account, id, amount, data);
    }

    //////////////////////////////////////////////
    // HOOKS
    //////////////////////////////////////////////

    /**
     * @dev Pre validate the token transfer to ensure that the actual transfer will not fail under
       the same conditions. 
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param id The id of the token transfer.
     * @param amount The amount of tokens to transfer.
     * @param data Optional data field to include in events.
     */
	function checkTransferIsValid(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        transferToZeroAddress(to)
        sufficientTokens(from, id, amount)
        returns (bool)
    {
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        super._beforeTokenTransfer(_msgSender(), from, to, ids, amounts, data);
        super._beforeCallSeedCores(_msgSender(), from, to, ids, amounts, data);

		return true;
	}

    /**
     * @dev ERC-1155 before transfer hook. Used to pre-validate the transfer with the SeedCores. 
     * @param operator The address of the contract owner/operator.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param ids An array of token IDs for the token transfer.
     * @param amounts An array of integer amounts for each of the token IDs in the token transfer.
     * @param data Optional data field to include in events.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		internal
		override(ERC1155, ERC1155Pausable)
	{
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        super._beforeCallSeedCores(operator, from, to, ids, amounts, data);
	}

    /**
     * @dev ERC-1155 after transfer hook. Used to update the Shareholder registry to reflect the transfer. 
     * @param operator The address of the contract owner/operator.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param ids An array of token IDs for the token transfer.
     * @param amounts An array of integer amounts for each of the token IDs in the token transfer.
     * @param data Optional data field to include in events.
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		internal
		override(ERC1155)
	{
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        super._afterCallSeedCores(operator, from, to, ids, amounts, data);
	}

}
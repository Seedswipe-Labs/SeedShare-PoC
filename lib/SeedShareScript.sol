// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Inherits
import '../interface/ISeedShareScript.sol';
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// Interfaces
import '../interface/ISeedShare.sol';

/**

    SeedShareScript is, in essence, an ERC20 token wrapper contract. SeedShareScript may be used to 
    wrap SeedShare tokens so that they can be used in environments where trustlessness and standard
    erc20 compliance is important, such as defi.

    SeedShare tokens may be deposited minting a proportional amount of Script tokens that can be used
    in their place. When the user wishes to withdraw the underlying equity they can burn the Script 
    tokens, assuming that they pass the compliance checks neccesary for prospective Shareholders. 
    If they do not they can either take steps to ensure they are compliant or pass the Script tokens
    onward. If there is any doubt surrounding the elligibility of the a receiver, they can query the
    SeedShare `checkTransferIsValid` function.
    
    SeedShareScript differs from traditional wrappers is that it encodes a legal agreeement to 
    clarifying the legal status of the Script tokens and how they relate to the underlying equity in 
    the SeedShare contract. This can be accessed via the uri() function.

 */

contract SeedShareScript is ISeedShareScript, ERC20, ERC1155Holder {

    ////////////////
    // CONTRACT
    ////////////////
        
    /**
    * @dev The corresponding SeedShare contract.
    */
    ISeedShare public _Share;

    ////////////////
    // STATE
    ////////////////

    /**
    * @dev Share token ID in the Share contract.
    */
    uint256 public _id;

    /**
    * @dev Metadata uri for legal contract.
    */
	string public _uri;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        ISeedShare Share,
        uint256 id,
        string memory name_,
        string memory symbol_,
        string memory uri_
    )
        ERC20(name_, symbol_)
    {
        _id = id;
        _uri = uri_;
        _Share = ISeedShare(Share);
    }

    ////////////////
    // MODIFIERS
    ////////////////

    /**
     * @dev Pre-validate the transfer to ensure the recipient is elligible.
     * @param from The transfering address.
     * @param amount  The amount of Shares to transfer.
     */
    modifier validTransfer(
        address from, 
        uint256 amount
    ) {
        if (!_Share.checkTransferIsValid(address(this), from, _id, amount, ""))
            revert TransferInvalid();
        _;
    }

    //////////////////////////////////////////////
    // WRAP | UNWRAP
    //////////////////////////////////////////////
    
    /**
     * @dev Deposit erc-1155 SeedShare tokens into the contract and receive minted erc-20 Script tokens for use in defi.
     * @param from The transfering address.
     * @param amount  The amount of Shares to transfer.
     */
    function wrapTokens(
        address from,
        uint256 amount
    )
        public
    {
        // Handle deposit of ERC1155 tokens
        _Share.safeTransferFrom(from, address(this), _id, amount, "");
        
        // Mint Script
        _mint(from, amount);

        // Event
        emit WrappedTokens(from, amount);
    }

    /**
     * @dev Burn erc-20 and receive the underlying SeedShare tokens.
     * @param to The receiving address.
     * @param amount  The amount of Shares to transfer.
     */
    function unWrapTokens(
        address to, 
        uint256 amount
    )
        public
        validTransfer(to, amount)
    {
        // Handle unwrap if done by third party
        if (msg.sender != to) {
            uint _allowance =  allowance(to, msg.sender);
            if (_allowance < amount) 
                revert BurnExceedAllowance();
            uint256 decreasedAllowance =  _allowance - amount; 
            _approve(to, msg.sender, decreasedAllowance);
        }
        
        // Burn the Script
        _burn(to, amount);
        
        // Return _Share
        _Share.safeTransferFrom(address(this), to, _id, amount, "" );

        // Event
        emit UnwrappedTokens(to, amount);
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the address of the corresponding SeedShare contract.
     */
    function getSeedShare()
        public
        view
        returns (address)
    {
        return address(_Share);
    }

    /**
     * @dev Returns the token ID for this wrapper token. Each wrapper is locked to a single token ID.
     */
    function getTokenId()
        public
        view
        returns (uint256)
    {
        return _id;
    }

    /**
     * @dev Returns the metadata uri for this wrapper token.
     */
    function uri()
        public
        view
        returns (string memory)
    {
        return _uri;
    }
}
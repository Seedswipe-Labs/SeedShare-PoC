// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './SeedCore.sol';
import '../interface/ISeedCoreRegistry.sol';

// Interfaces
import '../interface/ISeedBaseIdentityRegistry.sol';

/**

    SeedCoreRegistry keeps an on-chain record of the Shareholders.

 */

contract SeedCoreRegistry is SeedCore, ISeedCoreRegistry  {

    ////////////////
    // INTERFACES
    ////////////////

    /**
     * @dev The SeedShare identity registry.
     */ 
    ISeedBaseIdentityRegistry _identity;

    ////////////////
    // STATES
    ////////////////
	
    /**
     * Mapping from token ID to the addresses of all Shareholders.
     */
    mapping(uint256 => address[]) public _ShareholdersByToken;

    /**
     * Mapping from token ID to the exists status of the Shareholder.
     */
    mapping(uint256 => mapping(address => bool)) public _ShareholderExistsByAccountByToken;

    /**
     * Mapping from token ID to the country code to amount of Shareholders per country.
     */
    mapping(uint256 => mapping(uint16 => uint256)) public _ShareholderCountByCountryByToken;

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    /**
     * @dev Updates the Shareholder registry to reflect a Share transfer.
     * @param from The sending address. 
     * @param to The receiving address.
     * @param tokenId The token ID for the token to be transfered.
     * @param amount The integer amount of tokens to be transfered.
     */
    function transferred(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        returns (bool)
    {
        updateShareholders(to, tokenId);
        pruneShareholders(from, tokenId);

        return true;
    }

    //////////////////////////////////////////////
    // UPDATES
    //////////////////////////////////////////////

    /**
     * @dev Adds a new Shareholder and corresponding details to the Shareholder registry.
     * @param account The address of the account to either add or update in the Shareholder registry.
     * @param tokenId The token ID to add or update for the user. 
     */
    function updateShareholders(
        address account,
        uint256 tokenId
    )
        public
        // #TODO Security?
    {
        if (_ShareholderExistsByAccountByToken[tokenId][account]) {
            _ShareholdersByToken[tokenId].push(account);
            _ShareholderExistsByAccountByToken[tokenId][account] = true;
            _ShareholderCountByCountryByToken[tokenId][_identity.getCountryByAddress(account)]++;
                // #TODO, get Shareholder manually or ??
        }
    }

    /**
     * @dev Rebuilds the Shareholder registry and trims any Shareholders who no longer have Shares.
     * @param from The address of the user to remove from the Shareholder registry.
     * @param tokenId The token ID in to prune the Shareholder from.
     */
    function pruneShareholders(
        address from,
        uint256 tokenId
    )
        public
        // #TODO Security?
    {
        if (from != address(0) && _ShareholderExistsByAccountByToken[tokenId][from]) {
            
            // If Shareholder does not still have Shares trim the indicies
            if (_Share.balanceOf(from, tokenId) == 0) {

                for (uint8 i = 0; i < _ShareholdersByToken[tokenId].length; i++)
                    if (_ShareholdersByToken[tokenId][i] == from)
                        delete _ShareholdersByToken[tokenId][i];

                _ShareholderExistsByAccountByToken[tokenId][from] = false;
                _ShareholderCountByCountryByToken[tokenId][_identity.getCountryByAddress(from)]--;
            }
        }
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Sets the identity registry contract.
     * @param identity The address of the SeedBaseIdentityRegsitry contract.
     */
    function setIdentities(
        address identity
    )
        public 
    {
        _identity = ISeedBaseIdentityRegistry(identity);

        // Event
        emit UpdatedSeedBaseIdentityregistry(identity);
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the address of Shareholder by index.
     * @param tokenId The token ID to query.
     * @param index The Shareholder index.
     */
    function getHolderAt(
        uint256 tokenId,
        uint256 index
    )
        public
        view
        returns (address)
    {
        return _ShareholdersByToken[tokenId][index];
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
        return _ShareholderCountByCountryByToken[tokenId][country];
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
}
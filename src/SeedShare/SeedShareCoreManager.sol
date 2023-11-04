// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import './interfaces/ISeedCore.sol';

contract SeedShareCoreManager {

    ////////////////
    // ERRORS
    ////////////////

    error InitCallFail();

    error Sponsored();

    error NotSeedCore();

    ////////////////
    // STATE
    ////////////////

    mapping(address => bool) public SeedCores;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    function init(
        address[] memory SeedCores_,
        bytes[] memory SeedCoresData_
    )
        public
        payable
    {
        // Ensure SeedCore array parity
        if (SeedCores_.length != SeedCoresData_.length)
            revert NoArrayParity();

        // If has SeedCores
        if (SeedCores_.length != 0) {
            for (uint8 i = 0; i < SeedCores_.length; i++) {
                SeedCores[SeedCores_[i]] = true;

                if (SeedCoresData_[i].length != 0) {
                    (bool success, ) = SeedCores_[i].call(SeedCoresData_[i]);

                    // If init failed 
                    if (!success)
                        revert InitCallFail();
                }
            }
        }
    }

    //////////////////////////////////////////////
    // SeedCore FUNCTIONS
    //////////////////////////////////////////////
     
    /**
     * @dev 
     * @param SeedCore
     * @param SeedCoreData
     */
    function _setSeedCore(
        address SeedCore, 
        bytes calldata SeedCoreData
    )
        internal
    {

        /**
        
            for (uint256 i; i < prop.accounts.length; i++) {
                if (prop.amounts[i] != 0) 
                    SeedCores[prop.accounts[i]] = !SeedCores[prop.accounts[i]];
            
                if (prop.payloads[i].length != 0) ISeedCore(prop.accounts[i])
                    .setSeedCore(prop.payloads[i]);
            }
        
         */

    }

    /**
     * @dev 
     * @param SeedCore
     * @param SeedCoreData
     */
    function _callSeedCores(
        address SeedCore, 
        bytes calldata SeedCoreData
    )
        internal
    {
        // #TODO
        for (uint 8 i = 0; i < SeedCores.length; i++)
            // Validate that SeedCore needs calling
                // Encode data fields 
                // _callSeedCore with data
                
                // ??
                // Get return values (target, returnData)
                // If target, 
                    // _callSeedCore with returnData
    }

    /**
     * @dev 
     * @param SeedCore
     * @param SeedCoreData
     */
    function _callSeedCore(
        address SeedCore, 
        bytes calldata SeedCoreData
    )
        internal
    {
        // Ensure SeedCore returns bool true in from mapping of SeedCores
        if (!SeedCores[SeedCore] && !SeedCores[msg.sender])
            revert NotSeedCore();
        
        (returnData) = ISeedCore(SeedCore).callSeedCore{value: msg.value}(operator, from, to, ids, amounts, data, SeedCoreData);
        
    }


}
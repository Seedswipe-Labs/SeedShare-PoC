// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

// Inherited
import 'openzeppelin-contracts/contracts/access/Ownable.sol';

// Interfaces
import '../interface/ISeedShare.sol';

/**

	TODO, reduce this to a generalised extension interface inhereted by all SeedCores.

 */

contract SeedCore is ISeedCore, Ownable {

    ////////////////
    // INTERFACES
    ////////////////

    /**
     * @dev The Share contract instance.
     */ 
    ISeedShare _Share;

    //////////////////////////////////////////////
    // SeedCore FUNCTIONS
    //////////////////////////////////////////////

    function setSeedCore(
        bytes calldata SeedCoreData
    )
        public
        nonReentrant
        virtual
    {
        setShare(msg.sender); 
        
        (/* fields, fields, fields */) = abi.decode(SeedCoreData, (/* fields, fields, fields */));
        
        emit SeedCoreSet(SeedCoreData);
    }

    function callSeedCore(
        bytes calldata SeedCoreData
    )
        public
        returns (bytes calldata returnData)
    {
        () = abi.decode(SeedCoreData, ());

        // Function stuff

        returnData = SeedCoreData; // #TODO

        emit SeedCoreCalled(SeedCoreData);
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Sets the SeedShare contract.
     * @param Share The address of the SeedShare contract.
     */
    function setShare(
        address Share
    )
        public 
        onlyShareOrOwner
    {
        _Share = ISeedShare(Share);

        // Event
        emit UpdatedSeedShare(Share);
    }
    
}
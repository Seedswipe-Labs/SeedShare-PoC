// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./utils/Utils.sol";

import "../src/SeedShare/SeedCoreRegistry.sol";

contract SeedCoreRegistryTest is Test {
    
    // Utils
    Utils public _utils;

    // Compliance
    SeedCoreRegistry public _registry;

    // Shareholders
    uint256 _noShareholders = 4;
    address[] public _Shareholders;

    // Claim topics
    enum Schema {
        Certified,
        Accredited,
        SelfCertified
    }

    // Set up
    function setUp() public {

        // Get utils
        _utils = new Utils();

        // Create testing payees
        _Shareholders = _utils.createUsers(_noShareholders);

        // Compliance 
		_registry = new SeedCoreRegistry(address(this), address(1));

    }


    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    function testcreateToken() public {

        uint256 tokenId = 1;
        uint256 ShareholderLimit = 100;
        uint256 ShareholdingMinimum = 5 ether;
        bool ShareholdingNonDivisible = true;

		_registry.createToken(tokenId, ShareholderLimit, ShareholdingMinimum, ShareholdingNonDivisible);

        uint256 newShareholderLimit = _registry.getShareholderLimit(tokenId);
		uint256 newShareholdingMinimum = _registry.getShareholdingMinimum(tokenId);
		bool newShareholdingNonDivisible = _registry.checkNonDivisible(tokenId);

		assertTrue(ShareholderLimit == newShareholderLimit, "Shareholder limit mismatch");
		assertTrue(ShareholdingMinimum == newShareholdingMinimum, "Shareholding minimum mismatch");
		assertTrue(ShareholdingNonDivisible == newShareholdingNonDivisible, "Nondivisibible mismatch");
	}

}
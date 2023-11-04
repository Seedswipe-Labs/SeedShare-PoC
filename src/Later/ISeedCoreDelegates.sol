// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './SeedCore.sol';
import '../interface/ISeedCoreDelegates.sol';

interface ISeedCoreDelegates {

  	////////////////
    // INTERFACES
    ////////////////

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate, uint256 id );

    event DelegateVotesChanged( address indexed delegate, uint256 indexed id, uint256 previousBalance, uint256 newBalance );

  	////////////////
    // ERRORS
    ////////////////

    error Undetermined();

    error Overflow();

	

}
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

interface ISeedCore {

    ////////////////
    // EVENTS
    ////////////////

    event SeedCoreSet(bytes SeedCoreData);

    event SeedCoreCalled(bytes SeedCoreData);

    ////////////////
    // ERRORS
    ////////////////

    error NoArrayParity();

    //////////////////////////////////////////////
    // SeedCore FUNCTIONS
    //////////////////////////////////////////////

    function setSeedCore(bytes calldata SeedCoreData) external;

    function callSeedCore(bytes calldata SeedCoreData) external;
}
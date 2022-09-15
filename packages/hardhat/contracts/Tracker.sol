// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4; 

// Simple contract to keep track of contract addresses

contract Tracker {

    //
    address public stakerAddress;
    address public exampleExternalContractAddress;

    constructor(address _stakerAddress, address _exampleExternalContractAddres) {
        stakerAddress = _stakerAddress;
        exampleExternalContractAddress = _exampleExternalContractAddres;
    }

}
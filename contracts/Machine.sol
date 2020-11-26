// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./Storage.sol";

contract Machine {
    
    Storage public storageAddress;

    constructor(Storage addr) public {
        storageAddress = addr;
    }
    
    function saveValue(uint x) public returns (bool) {
        storageAddress.store(x);
        return true;
    }

    function getValue() public view returns (uint) {
        return storageAddress.retrieve();
    }
}
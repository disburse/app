// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./Storage.sol";

contract Machine {
    
    address public admin;
    Storage public storageAddress;

    modifier restricted() {
        require(
        msg.sender == admin,
        "This function is restricted to the administrator"
        );
        _;
    }

    constructor() public {
        admin = msg.sender;
    }
    
    function setStorageAddress(Storage _address) public restricted {
        storageAddress = _address;
    }

    function saveValue(uint x) public returns (bool) {
        storageAddress.store(x);
        return true;
    }

    function getValue() public view returns (uint) {
        return storageAddress.retrieve();
    }
}
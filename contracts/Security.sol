// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Security {

    bool public isActive = true;
    address public admin;

    modifier adminOnly {
        require(admin == msg.sender);
        _;   
    }
    
    modifier active {
        require(isActive == true);
        _;
    }
    
    constructor(address _address) public {
        admin = _address;
    }
    
    function toggleCircuitBreaker() public {
        require(admin == msg.sender);
        isActive = !isActive;
    }
}
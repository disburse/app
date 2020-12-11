// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Pausable.sol";

contract Security is Pausable {

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
    
    constructor(address _address) Pausable() public {
        admin = _address;
    }
    
    function toggleCircuitBreaker() public {
        require(admin == msg.sender);
        isActive = !isActive;
    }
}
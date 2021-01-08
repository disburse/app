// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Secure is Pausable, ReentrancyGuard {

    bool public isActive = true;
    address public admin = msg.sender;

    modifier restricted() {
        require(
        msg.sender == admin,
        "This function is restricted to the contract's owner"
        );
        _;
        // '_;' represents the modified function's body
    }
    
    modifier active {
        require(isActive == true);
        _;
    }
    
    constructor(address _address) Pausable() ReentrancyGuard() public {
        admin = _address;
    }
    
    function changeOwner(address newAdmin) public restricted {
        admin = newAdmin;
    }

    function toggleCircuitBreaker() public {
        require(admin == msg.sender);
        isActive = !isActive;
    }
}
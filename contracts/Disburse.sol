// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Disburse {
    
    address public owner;
    uint256 deadline;                               // persistent contract storage
    mapping(address => uint256) public balanceOf;   // balances, indexed by addresses

    modifier ownerOnly {
        require(owner == msg.sender);
        _;   // <--- note the '_', which represents the modified function's body
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeOwner(address newOwner) public ownerOnly {
        owner = newOwner;
    }
    
    function deposit() payable public {
        // nothing to do!
    }
    
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);

        balanceOf[msg.sender] += amount;     // adjust the account's balance
    }
    
    function withdraw() public ownerOnly {
        msg.sender.transfer(address(this).balance);
    }
    
    function withdraw(uint256 amount) public {
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }    
    
    // Retrieve contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function setDeadline(uint256 numberOfDays) public payable {
        deadline = block.timestamp + (numberOfDays * 1 days);
    }

    function disburse() public payable {
        require(block.timestamp >= deadline);
        msg.sender.transfer(address(this).balance);
    }
    
}
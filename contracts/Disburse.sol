// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Disburse {
    
    address public admin;
    uint256 deadline;
    
    modifier restricted() {
        require(
        msg.sender == admin,
        "This function is restricted to the administrator"
        );
        _;
    }
    
    function deposit() payable public {
        // nothing to do!
    }
    
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        // nothing else to do!
    }
    
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
    
    // Retrieve contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function setDisburseDate(uint256 numberOfDays) public {
        
        // The Ethereum Virtual Machine represents time as the (integer) number of seconds 
        // since the “Unix epoch”
        
        // https://www.epochconverter.com/

        // Solidity provides convenient time units like days and years, which are helpful 
        // in computing time spans.
        
        deadline = block.timestamp + (numberOfDays * 1 days);
    }
    
    function disburse() public payable {
        
        require(block.timestamp >= deadline);

        msg.sender.transfer(address(this).balance);
    }
    
}
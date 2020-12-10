// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Trust {
    
    uint256 public deadline;   
    address payable public beneficiary;
    mapping(address => uint256) public balanceOf;

    // Declare an array of payable recipients
    // address payable[] recipients; 

    function initiateTrust() public payable {
        balanceOf[msg.sender] = msg.value;
    }
    
    function setBeneficiary(address payable _address) public {
        beneficiary = _address;
    }
    
    function getTrustBalance() public view returns(uint256 _balance) {
        // Contract Balance
        _balance = address(this).balance;
    }
    
    function disburseFunds() public {
        bool deadlinePassed = getDeadlinePassed();
        
        if (deadlinePassed){

            // This sends the entire contract balance to the beneficiary
            beneficiary.transfer(address(this).balance);

            // Syntax to transfer to the address calling the contract
            // msg.sender.transfer();
        }
    }
    
    function getDeadlinePassed() public view returns (bool) {
        
        // Ensure deadline has been set
        if (deadline == 0) return false;
        
        if (block.timestamp >= deadline) return true;
        
        return false;
    }
    
    function getBlockTimestamp() public view returns(uint256) {
        return block.timestamp;
    }
    
    function setDeadlineSeconds(uint256 sec) public {
        deadline = block.timestamp + sec;
    }
    
    function setDeadlineDays(uint256 numberOfDays) public {
        deadline = block.timestamp + (numberOfDays * 1 days);
    }

    // Pure functions do not read or modify any storage data
    // View functions can read from storage data
    function calculatePercentage(uint256 _amount, uint256 _bps) public pure returns(uint256) {
        
        // Ensure amount being calculated is large enough
        require ((_amount / 10000) * 10000 == _amount, 'too small');
        
        // Example: Assume 185 basis points, which is the same as 0.0185
        // To turn 0.0185 into a non-decimal it must be times by 10,10000
        // 0.0185 = 10,000 
        // Then to return the number to its original value it must be divided by 10,000
        
        return _amount * _bps / 10000;
    }

}
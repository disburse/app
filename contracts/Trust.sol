// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Trust {
    
    uint256 public deadline;   
    address payable public beneficiary;
    mapping(address => uint256) public balanceOf;

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
            beneficiary.transfer(address(this).balance);
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

}
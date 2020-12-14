// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

contract DisburseV1 {
 
     struct Beneficiary { 
        address trust;
        uint256 deadline;
        uint256 amount;
        bool invest;
    }

    // Mapping that outlines how funds should be disbursed to beneficiaries
    mapping(address => mapping(address => Beneficiary)) beneficiaries;

    // Mapping that records total balance of funds
    mapping(address => uint256) balanceOf;

    function initiateTrust() public payable {
        balanceOf[msg.sender] += msg.value;  // Add funds to any previous funds
    }

    function getTrustBalance() public view returns(uint256 _balance) {
        _balance = balanceOf[msg.sender];
    }

    function getContractBalance() public view returns(uint256 _balance) {
        _balance = address(this).balance;
    }

    function addBeneficiarySeconds(address _beneficiaryAddress, uint256 _seconds, uint256 _amount) public {
        addBeneficiary(msg.sender, _beneficiaryAddress, _seconds, _amount);
    }

    function addBeneficiaryDays(address _beneficiaryAddress, uint256 _days, uint256 _amount) public {
        uint256 sec =  _days * 86400;               // Determine number of seconds
        addBeneficiary(msg.sender, _beneficiaryAddress, sec, _amount);
    }

    function addBeneficiary(address _trustAddress, address _beneficiaryAddress, uint256 _seconds, uint256 _amount) internal {
        
        // Determine deadline date
        uint256 deadline = block.timestamp + _seconds;
        
        // Create beneficiary
        Beneficiary memory beneficiary = Beneficiary(_trustAddress, deadline, _amount, false);
        
        // Add beneficiary to mapping
        beneficiaries[_trustAddress][_beneficiaryAddress] = beneficiary;
    }
    
    function getBeneficiary(address _address) public view returns(Beneficiary memory _beneficiary) {
        _beneficiary = beneficiaries[msg.sender][_address];
    }
    
    function deadlinePassed(address _beneficiaryAddress) public view returns (bool) {
        
        Beneficiary memory beneficiary = getBeneficiary(_beneficiaryAddress);
        
        // Ensure deadline has been set && has passed
        if (beneficiary.deadline != 0 && block.timestamp >= beneficiary.deadline) return true; 

        return false; 
    }
    
    function disburseFunds(address payable _beneficiaryAddress) public {
        
        bool passed = deadlinePassed(_beneficiaryAddress);
        
        if (passed) {
            
            Beneficiary memory beneficiary = getBeneficiary(_beneficiaryAddress);
            
            // Reduce trust balance
            balanceOf[beneficiary.trust] -= beneficiary.amount;
            
            // TODO: set the beneficiary to disbursed and the new amount to zero
            
            _beneficiaryAddress.transfer(beneficiary.amount);
        }
    }
}
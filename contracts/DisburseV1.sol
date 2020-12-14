// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

contract DisburseV1 {
 
     struct Beneficiary { 
        uint256 deadline;
        uint256 amount;
        bool invest;
    }

    mapping(address => mapping(address => Beneficiary)) beneficiaries;

    function addBeneficiarySeconds(address _address, uint256 _seconds, uint256 _amount) public {
        addBeneficiary(_address, _seconds, _amount);
    }

    function addBeneficiaryDays(address _address, uint256 _days, uint256 _amount) public {
        uint256 sec =  _days * 86400;               // Determine number of seconds
        addBeneficiary(_address, sec, _amount);
    }

    function addBeneficiary(address _address, uint256 _seconds, uint256 _amount) internal {
        
        // Determine deadline date
        uint256 deadline = block.timestamp + _seconds;
        
        // Create beneficiary
        Beneficiary memory beneficiary = Beneficiary(deadline, _amount, false);
        
        // Add beneficiary to mapping
        beneficiaries[msg.sender][_address] = beneficiary;
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
}
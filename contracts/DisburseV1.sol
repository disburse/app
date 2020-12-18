// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

contract DisburseV1 {
 
     struct Beneficiary { 
        address trust;
        uint256 disburseDate;
        uint256 amount;
        bool backup;
        bool invest;
    }

    // Mapping that outlines how funds should be disbursed to beneficiaries
    mapping(address => mapping(address => Beneficiary)) beneficiaries;

    // Mapping that records total trust balance
    mapping(address => uint256) trustBalance;
    
    // Mapping the current beneficiary balance, which may be less than the trust balance
    mapping(address => uint256) beneficiaryBalance;

    function contributeToTrust() public payable {
        trustBalance[msg.sender] += msg.value;  // Add funds to any previous funds
    }

    function getTrustBalance(address _trustAddress) public view returns(uint256 _balance) {
        _balance = trustBalance[_trustAddress];
    }

    function withdrawTrustBalance() public {
        trustBalance[msg.sender] = 0;
        msg.sender.transfer(address(this).balance);
    }

    function getBeneficiaryBalance(address _trustAddress) internal view returns(uint256 _balance) {
        _balance = beneficiaryBalance[_trustAddress];
    }

    function getContractBalance() public view returns(uint256 _balance) {
        _balance = address(this).balance;
    }

    function addBeneficiarySeconds(address _beneficiaryAddress, uint256 _seconds, uint256 _amount) public {
        addBeneficiary(_beneficiaryAddress, _seconds, _amount);
    }

    function addBeneficiaryDays(address _beneficiaryAddress, uint256 _days, uint256 _amount) public {
        uint256 sec =  _days * 86400;               // Determine number of seconds
        addBeneficiary(_beneficiaryAddress, sec, _amount);
    }

    function addBeneficiary(address _beneficiaryAddress, uint256 _seconds, uint256 _amount) internal {
        
        // Only trust owner can add beneficiary 
        address trustAddress = msg.sender;
        
        // Ensure trust has been previously intiated
        uint256 trustAmount = getTrustBalance(trustAddress);
        require(trustAmount > 0);
        
        // Ensure trust has sufficient funds to disburse to beneficiary
        uint256 beneficiaryAmount = getBeneficiaryBalance(trustAddress);
        require (beneficiaryAmount + _amount <= trustAmount);
        
        // Update total beneficiary amount
        beneficiaryBalance[trustAddress] += _amount;

        // Determine beneficiary disbursement date
        uint256 deadline = block.timestamp + _seconds;

        // Create new beneficiary
        Beneficiary memory beneficiary = Beneficiary(trustAddress, deadline, _amount, false, false);
        
        // Add beneficiary to trust
        beneficiaries[trustAddress][_beneficiaryAddress] = beneficiary;
    }
    
    function getBeneficiary(address _beneficiaryAddress) public view returns(Beneficiary memory _beneficiary) {
        // Only trust owner can get details of beneficiary
        _beneficiary = beneficiaries[msg.sender][_beneficiaryAddress];
    }
    
    function deadlinePassed(address _beneficiaryAddress) public view returns (bool) {
        
        Beneficiary memory beneficiary = getBeneficiary(_beneficiaryAddress);
        
        // Ensure deadline has been set && has passed
        if (beneficiary.disburseDate != 0 && block.timestamp >= beneficiary.disburseDate) return true; 

        return false; 
    }
    
    // This function should be callable anyone, including an external job
    function disburseFunds(address payable _beneficiaryAddress) public {
        
        bool passed = deadlinePassed(_beneficiaryAddress);
        
        if (passed) {
            
            Beneficiary memory beneficiary = getBeneficiary(_beneficiaryAddress);
            uint256 disburseAmount = beneficiary.amount;
            
            // Reduce trust balance
            trustBalance[beneficiary.trust] -= disburseAmount;
            
            // Reduce total beneficiary claims
            beneficiaryBalance[beneficiary.trust] -= disburseAmount;
            
            // Reset the beneficiary amount and disbursement date
            beneficiaries[beneficiary.trust][_beneficiaryAddress].amount = 0;
            beneficiaries[beneficiary.trust][_beneficiaryAddress].disburseDate = 0;
        
            // Finally, disburse funds to beneficiary
            _beneficiaryAddress.transfer(disburseAmount);
        }
    }
}
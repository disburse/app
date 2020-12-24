// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

contract DisburseV1 {
 
     struct Beneficiary { 
        uint256 id;
        address trustAddress;
        address beneficiaryAddress;
        uint256 disburseDate;
        uint256 amount;
        bool complete;
    }

    // Mapping that outlines how funds should be disbursed to beneficiaries
    mapping(address => mapping(uint256 => Beneficiary)) beneficiaries;

    // Mapping that records total trust balance
    mapping(address => uint256) trustBalance;
    
    // Mapping to record total beneficiaries for each trust
    mapping(address => uint256) beneficiaryCount;

    // Mapping to record total beneficiaries for each trust
    mapping(address => uint256) topBeneficiaryId;

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

    function withdrawAmountFromTrustBalance(uint256 _amount) public {
        trustBalance[msg.sender] -= _amount;
        msg.sender.transfer(_amount);
    }

    function getBeneficiaryBalance(address _trustAddress) public view returns(uint256 _balance) {
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

    function addBeneficiary(address _beneficiaryAddress, uint256 _seconds, uint256 _amount) public {
        
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
        uint256 delayInSeconds = block.timestamp + _seconds;

        // Update to next available beneficiary id
        // NOTE: Id's cannot start at 0, otherwise the return id of an existing
        // address and non-existing address will look the same
        topBeneficiaryId[trustAddress] += 1;

        // Get beneficiary id
        uint256 id = topBeneficiaryId[trustAddress];
        
        // Create new beneficiary
        Beneficiary memory beneficiary = Beneficiary(
                                            id,
                                            trustAddress, 
                                            _beneficiaryAddress, 
                                            delayInSeconds, 
                                            _amount, 
                                            false);
        
        // Every key maps to something. If no value has been set yet, then the value is 0. 
        beneficiaries[trustAddress][id] = beneficiary;
        
        // Update total number of beneficiaries this trust is managing
        beneficiaryCount[trustAddress] += 1;
    }
    
    // Retrieve total number of beneficiaries of a partricular trust account
    function getBeneficiaryCount() public view returns(uint256 _count) {
        _count = beneficiaryCount[msg.sender];
    }

    // Counter that increments the id's of beneficiaries
    function getTopBeneficiaryId() public view returns(uint256 _count) {
        _count = topBeneficiaryId[msg.sender];
    }

    // Remove beneficiary at a unique id
    function removeBeneficiary(uint256 _id) public {
        // Retrieve beneficiary address
        Beneficiary memory beneficiary = beneficiaries[msg.sender][_id];

        if (beneficiary.id == _id){

            bool passedDisbursementDate = readyToDisburse(_id);

            // If the disbursement date has already passed, deletion of beneficiary is not permitted
            if (!passedDisbursementDate){
                // Reduce total beneficiary claims
                beneficiaryBalance[msg.sender] -= beneficiary.amount;
                
                // Update total number of beneficiaries this trust is managing
                beneficiaryCount[msg.sender] -= 1;

                // will delete the struct
                delete beneficiaries[msg.sender][_id];
            }
        }
    }

    // Retrieve beneficiary based on it's unique id
    function getBeneficiary(uint256 _id) public view returns(Beneficiary memory _beneficiary) {
        // Only trust owner can get details of beneficiary
        _beneficiary = beneficiaries[msg.sender][_id];
    }
    
    // What happens if we have the same beneficiary Address on two different disbursement dates?
    // This implies there is more than one idea associated with an address.

    function getBeneficiaryId(address _beneficiaryAddress) public view returns(uint256 _id) {
        
        // NOTE: Id's cannot be zero indexed, otherwise the return id of an existing
        // address and non-existing address will look the same
        
        // Retrieve the Id of the last most beneficiary
        uint256 topId = topBeneficiaryId[msg.sender];
        
        for (uint256 id = 0; id <= topId; id++){
            Beneficiary memory beneficiary = beneficiaries[msg.sender][id];
            
            if (beneficiary.beneficiaryAddress == _beneficiaryAddress){
                _id = beneficiary.id;
                break;
            }
        }
    }

    // Determine if the disbursement date has passed
    function readyToDisburse(uint256 _id) public view returns (bool) {
        
        Beneficiary memory beneficiary = beneficiaries[msg.sender][_id];
        
        // Ensure deadline has been set && has passed
        if (beneficiary.disburseDate != 0 && block.timestamp >= beneficiary.disburseDate) return true; 

        return false; 
    }  

    // TODO: This function should be callable anyone, including an external job
    // As coded, this function is only callable by the trust owner
    // Beneficiary id's are not known by the general public
    function disburseFunds(uint256 _id) public {
        
        Beneficiary memory beneficiary = beneficiaries[msg.sender][_id];
        bool passedDisbursementDate = readyToDisburse(_id);

        if (beneficiary.complete == false && passedDisbursementDate) {
            
            address payable beneficiaryAddress = payable(beneficiary.beneficiaryAddress);
            uint256 amount = beneficiary.amount;
            
            // Reduce trust balance
            trustBalance[beneficiary.trustAddress] -= amount;
            
            // Reduce total beneficiary claims
            beneficiaryBalance[beneficiary.trustAddress] -= amount;
            
            // Set the complete flag to true
            beneficiaries[beneficiary.trustAddress][_id].complete = true;

            // Finally, disburse funds to beneficiary
            beneficiaryAddress.transfer(amount);
        }
    }
}
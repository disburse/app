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
        bool cancelAllowed;
        bool complete;
    }

    struct Disbursement { 
        uint256 id;
        address trustAddress;
        uint256 beneficiaryId;
    }

    // Events:
    event DisburseFundsEvent(address from, address to, uint256 amount);
    event DisbursementCompleteEvent(bool flag);
    event DisbursementReadyEvent(bool flag);
    event CancelAllowed(bool flag);
    event RemoveBeneficiary(bool flag);

    // Mapping that outlines how funds should be disbursed to beneficiaries
    mapping(address => mapping(uint256 => Beneficiary)) beneficiaries;

    // Mapping to record total beneficiaries for each trust
    mapping(address => uint256) beneficiaryCount;

    // Mapping to record last beneficiary id for each trust
    mapping(address => uint256) topBeneficiaryId;

    // Mapping that records total trust balance
    mapping(address => uint256) trustBalance;
    
    // Mapping the current beneficiary balance, which may be less than the trust balance
    mapping(address => uint256) beneficiaryBalance;

    // Mapping that outlines all upcoming disbursements to beneficiaries
    mapping(address => mapping(uint256 => Disbursement)) public disbursements;

    // Mapping to record total disbursements for each beneficiary
    mapping(address => uint256) public disbursementCount;

    // Mapping to record last disbursement id for each beneficiary
    mapping(address => uint256) public topDisbursementId;

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

    function addBeneficiarySeconds(address _beneficiaryAddress, uint256 _seconds, uint256 _amount, bool _cancelAllowed) public {
        addBeneficiary(_beneficiaryAddress, _seconds, _amount, _cancelAllowed);
    }

    function addBeneficiaryDays(address _beneficiaryAddress, uint256 _days, uint256 _amount, bool _cancelAllowed) public {
        uint256 sec =  _days * 86400;               // Determine number of seconds
        addBeneficiary(_beneficiaryAddress, sec, _amount, _cancelAllowed);
    }

    function addBeneficiary(address _beneficiaryAddress, uint256 _seconds, uint256 _amount, bool _cancelAllowed) public {
        
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
        uint256 beneficiaryId = topBeneficiaryId[trustAddress];

        // Create new beneficiary
        Beneficiary memory beneficiary = Beneficiary(
                                            beneficiaryId,
                                            trustAddress, 
                                            _beneficiaryAddress, 
                                            delayInSeconds, 
                                            _amount, 
                                            _cancelAllowed,
                                            false);
                                            

        // Every key maps to something. If no value has been set yet, then the value is 0. 
        beneficiaries[trustAddress][beneficiaryId] = beneficiary;

        // Update total number of beneficiaries this trust is managing
        beneficiaryCount[trustAddress] += 1;

        // Add disbursement
        addDisbursement(trustAddress, beneficiaryId, _beneficiaryAddress);
    }
    
    // Add a disbursement once a new beneficiary has been added 
    function addDisbursement(address _trustAddress, uint256 _beneficiaryId, address _beneficiaryAddress) internal {

        // Update to next available disbursement id
        topDisbursementId[_beneficiaryAddress] += 1;        
        
        // Get disbursement id that was just incremented
        uint256 disbursementId = topDisbursementId[_beneficiaryAddress];

        // Create new disbursement
        Disbursement memory disbursement = Disbursement(
                                            disbursementId,
                                            _trustAddress, 
                                            _beneficiaryId);

         // Every key maps to something. If no value has been set yet, then the value is 0. 
        disbursements[_beneficiaryAddress][disbursementId] = disbursement;
        
        // Update total number of disbursements this beneficiary is managing
        disbursementCount[_beneficiaryAddress] += 1;    
        
    }
    
    // Retrieve total number of beneficiaries of a partricular trust account
    function getBeneficiaryCount() public view returns(uint256 _count) {
        _count = beneficiaryCount[msg.sender];
    }

    // Counter that increments the id's of beneficiaries
    function getTopBeneficiaryId() public view returns(uint256 _count) {
        _count = topBeneficiaryId[msg.sender];
    }

    // Retrieve beneficiary based on it's unique id
    function getBeneficiary(uint256 _id) public view returns(Beneficiary memory _beneficiary) {
        // Only trust owner can get details of beneficiary
        _beneficiary = beneficiaries[msg.sender][_id];
    }
    
    // TODO FIX: What happens if we have the same beneficiary Address on two different disbursement dates?
    // This implies there is more than one ID associated with an address.

    function getBeneficiaryId(address _beneficiaryAddress) public view returns(uint256 _id) {
        
        // NOTE: Id's cannot be zero indexed, otherwise the return id of an existing
        // address and non-existing address will look the same
        
        // Retrieve the Id of the last most beneficiary
        uint256 topId = topBeneficiaryId[msg.sender];
        
        for (uint256 id = 0; id <= topId; id++){
            Beneficiary memory beneficiary = beneficiaries[msg.sender][id];
            
            if ((beneficiary.beneficiaryAddress == _beneficiaryAddress) &&
                (beneficiary.complete == false)){
                _id = beneficiary.id;
                break;
            }
        }
    }

    // Retrieve the disbursement ID associated with a given beneficiary ID
    function getDisbursementId(address _trustAddress, uint256 _beneficiaryId) public view returns(uint256 _id) {
        
        // Retrieve Beneficiary
        Beneficiary memory beneficiary = beneficiaries[_trustAddress][_beneficiaryId];
        
        // Retrieve the Id of the last disbursement
        uint256 topId = topDisbursementId[beneficiary.beneficiaryAddress];
        
        for (uint256 id = 0; id <= topId; id++){
            
            Disbursement memory disbursement = disbursements[beneficiary.beneficiaryAddress][id];
            
            if (disbursement.beneficiaryId == _beneficiaryId) {
                _id = disbursement.id;
                break;
            }
        }
    }

    // Determine if the disbursement date has passed
    function readyToDisburse(address _trustAddress, uint256 _id) public view returns (bool) {
        
        Beneficiary memory beneficiary = beneficiaries[_trustAddress][_id];
        
        // Ensure deadline has been set && has passed
        if (beneficiary.disburseDate != 0 && block.timestamp >= beneficiary.disburseDate) return true; 

        return false; 
    }  

    // This function should be callable anyone, including the beneficiary
    // This function will only execute AFTER the disbursement date, unlike removeBeneficiary which
    // executes BEFORE the disbursement date. 
    function disburseFunds(address _trustAddress, uint256 _beneficiaryId) public {
        
        Beneficiary memory beneficiary = beneficiaries[_trustAddress][_beneficiaryId];
        bool passedDisbursementDate = readyToDisburse(_trustAddress, _beneficiaryId);

        emit DisburseFundsEvent(_trustAddress, beneficiary.beneficiaryAddress, beneficiary.amount);
        emit DisbursementCompleteEvent(beneficiary.complete);
        emit DisbursementReadyEvent(passedDisbursementDate);

        // Will only execute AFTER disbursement date
        if (beneficiary.complete == false && passedDisbursementDate) {

            address payable beneficiaryAddress = payable(beneficiary.beneficiaryAddress);
            uint256 amount = beneficiary.amount;
            
            // Reduce trust balance
            trustBalance[beneficiary.trustAddress] -= amount;
            
            // Reduce total beneficiary claims
            beneficiaryBalance[beneficiary.trustAddress] -= amount;
            
            // Update total number of ACTIVE beneficiaries this trust is managing
            // This does not delete the history in the mapping
            beneficiaryCount[_trustAddress] -= 1;

            // Update total number of ACTIVE disbursements tied to this beneficiary
            // This does not delete the history in the mapping
            disbursementCount[beneficiary.beneficiaryAddress] -= 1;

            // Set the complete flag to true
            beneficiaries[beneficiary.trustAddress][_beneficiaryId].complete = true;

            // Finally, disburse funds to beneficiary
            beneficiaryAddress.transfer(amount);
        }
    }

    // Remove beneficiary at a unique id
    // This function will only execute BEFORE the disbursement date, unlike disburseFunds which
    // executes AFTER the disbursement date.
    function removeBeneficiary(uint256 _beneficiaryId) public {

        address _trustAddress = msg.sender;
        // Retrieve beneficiary address
        Beneficiary memory beneficiary = beneficiaries[_trustAddress][_beneficiaryId];
    
        if ((beneficiary.id == _beneficiaryId)  && (beneficiary.cancelAllowed == true)) {

            bool passedDisbursementDate = readyToDisburse(_trustAddress, _beneficiaryId);

            // Will only execute BEFORE disbursement date
            if (!passedDisbursementDate) {
                
                // Reduce total beneficiary claims
                beneficiaryBalance[_trustAddress] -= beneficiary.amount;
                
                // Update total number of beneficiaries this trust is managing
                beneficiaryCount[_trustAddress] -= 1;

                // Update total number of disbursements tied to this beneficiary
                disbursementCount[beneficiary.beneficiaryAddress] -= 1;

                uint256 disbursementId = getDisbursementId(_trustAddress, _beneficiaryId);

                // will delete the struct.  
                // This deletion must occur BEFORE the beneficiary deletion, otherwise address will not existing
                delete disbursements[beneficiary.beneficiaryAddress][disbursementId];
                
                 // will delete the struct
                delete beneficiaries[_trustAddress][_beneficiaryId];

                emit RemoveBeneficiary(true);
            }
        }
        else{
            emit RemoveBeneficiary(false);
        }
    }

}
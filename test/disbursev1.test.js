const assert = require('assert');
const Disburse = artifacts.require("DisburseV1");

var disburse;
var accounts;

contract("Disburse V1", () => {

    beforeEach(async () => {
        disburse = await Disburse.deployed();
        accounts = await web3.eth.getAccounts();
    });

    it("can retrieve empty trust balance", async () => {
        var balance = await disburse.getTrustBalance(accounts[0]);
        assert(balance == 0);
    });

    it("can contribute to trust", async () => {
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: accounts[0], value: weiAmount });
        var balance = await disburse.getTrustBalance(accounts[0]);
        assert(balance == weiAmount);
    });

    it("can withdraw trust balance", async () => {
        var originalBalance = await web3.eth.getBalance(accounts[0]);
        await disburse.withdrawTrustBalance({from: accounts[0]});
        var newBalance = await web3.eth.getBalance(accounts[0]);
        assert(newBalance >= originalBalance);
    });

    it("can withdraw specific amount from trust balance", async () => {
        var originalBalance = await web3.eth.getBalance(accounts[0]);

        // Withdraw from original balance and send to contract
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: accounts[0], value: weiAmount });
        
        // Send back to account from contract
        weiAmount = web3.utils.toWei('2', 'ether');
        await disburse.withdrawAmountFromTrustBalance(weiAmount, {from: accounts[0]});

        // Original Balance expected now: - 10 ETH + 2 ETH
        var originalETHBalance = web3.utils.fromWei(originalBalance, 'ether');
        var expected = originalETHBalance - 10 + 2;
        //console.log("EXPECTED: " + expected);

        // As we need to account for gas usage
        assert(originalETHBalance-8 >= expected);
        assert(expected >= originalETHBalance-10);

        // Withdraw all remaining funds
        await disburse.withdrawTrustBalance({from: accounts[0]});
    });

    it("can confirm beneficiary balance", async () => {
        var trustAddress = accounts[0];
        var beneficiaryAddress = accounts[1];
        var delayInSeconds = 30;
        var amount = web3.utils.toWei('2', 'ether');
        
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: trustAddress, value: weiAmount });

        var balance = await disburse.getBeneficiaryBalance(trustAddress);

        await disburse.addBeneficiary(
                            beneficiaryAddress, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});

        var balance = await disburse.getBeneficiaryBalance(trustAddress);
        var returnedBalance = web3.utils.toWei('2', 'ether');
        assert(balance == returnedBalance);

        var id = await disburse.getBeneficiaryId(beneficiaryAddress, {from: trustAddress});
        await disburse.removeBeneficiary(id, {from: trustAddress});

        var balance = await disburse.getBeneficiaryBalance(trustAddress);
        assert(balance == 0);

        await disburse.withdrawTrustBalance({from: trustAddress});
    });

    it("can add and remove beneficiary to trust", async () => {
        var trustAddress = accounts[0];
        var beneficiaryAddress = accounts[1];
        var delayInSeconds = 60;
        var amount = web3.utils.toWei('5', 'ether');
        
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: trustAddress, value: weiAmount });

        await disburse.addBeneficiarySeconds(
                            beneficiaryAddress, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});
        
        var id = await disburse.getBeneficiaryId(beneficiaryAddress, {from: trustAddress});
        var beneficiary = await disburse.getBeneficiary(id, {from: trustAddress});

        assert(beneficiary['id'] == id);
        assert(beneficiary['trustAddress'] == trustAddress);
        assert(beneficiary['beneficiaryAddress'] == beneficiaryAddress);
        assert(beneficiary['disburseDate'] > 0);
        assert(beneficiary['amount'] == amount);
        assert(beneficiary['complete'] == false);

        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 1);
        
        await disburse.removeBeneficiary(id, {from: trustAddress});
        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 0);

        await disburse.withdrawTrustBalance({from: trustAddress});
    });

    it("can add and remove disbursement attached to beneficiary", async () => {
        var trustAddress = accounts[0];
        var beneficiaryAddress = accounts[1];
        var delayInSeconds = 60;
        var amount = web3.utils.toWei('5', 'ether');
        
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: trustAddress, value: weiAmount });

        await disburse.addBeneficiarySeconds(
                            beneficiaryAddress, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});
        
        var id = await disburse.getBeneficiaryId(beneficiaryAddress, {from: trustAddress});
        //var beneficiary = await disburse.getBeneficiary(id, {from: trustAddress});

        var disbursementCount = await disburse.disbursementCount(beneficiaryAddress);
        assert(disbursementCount == 1);

        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 1);
        
        await disburse.removeBeneficiary(id, {from: trustAddress});
        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 0);

        // Ensure disbursement was also removed when the beneficiary was removed.
        disbursementCount = await disburse.disbursementCount(beneficiaryAddress);
        assert(disbursementCount == 0)

        await disburse.withdrawTrustBalance({from: trustAddress});
    });

    it("can confirm beneficiary count", async () => {
        var trustAddress = accounts[0];
        var beneficiary1 = accounts[1];
        var beneficiary2 = accounts[2];
        var delayInSeconds = 60;
        var amount = web3.utils.toWei('2', 'ether');
        
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: trustAddress, value: weiAmount });

        await disburse.addBeneficiary(
                            beneficiary1, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});

        var id1 = await disburse.getBeneficiaryId(beneficiary1, {from: trustAddress});
        var beneficiary = await disburse.getBeneficiary(id1);
        assert(beneficiary['id'] == id1);
                                                
        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 1);
                            
        await disburse.addBeneficiary(
                            beneficiary2, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});

        var id2 = await disburse.getBeneficiaryId(beneficiary2, {from: trustAddress});
        beneficiary = await disburse.getBeneficiary(id2);
        assert(beneficiary['id'] == id2);

        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 2);

        await disburse.removeBeneficiary(id2, {from: trustAddress});
        await disburse.removeBeneficiary(id1, {from: trustAddress});
        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 0);
        await disburse.withdrawTrustBalance({from: trustAddress});
    });

    it("can get all beneficiaries", async () => {
        var trustAddress = accounts[0];
        var beneficiary1 = accounts[1];
        var beneficiary2 = accounts[2];
        var delayInSeconds = 30;
        var amount = web3.utils.toWei('2', 'ether');
        
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: trustAddress, value: weiAmount });

        await disburse.addBeneficiary(
                            beneficiary1, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});

        await disburse.addBeneficiary(
                            beneficiary2, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});

        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 2);

        var id1 = await disburse.getBeneficiaryId(beneficiary1, {from: trustAddress});
        var id2 = await disburse.getBeneficiaryId(beneficiary2, {from: trustAddress});

        var beneficiary = await disburse.getBeneficiary(id1);
        assert(beneficiary['trustAddress'] == trustAddress);
        assert(beneficiary['beneficiaryAddress'] == beneficiary1);

        var beneficiary = await disburse.getBeneficiary(id2);
        assert(beneficiary['trustAddress'] == trustAddress);
        assert(beneficiary['beneficiaryAddress'] == beneficiary2);

        // Cleanup
        await disburse.removeBeneficiary(id1, {from: trustAddress});
        await disburse.removeBeneficiary(id2, {from: trustAddress});
        await disburse.withdrawTrustBalance({from: trustAddress});
    });

    it("cannot add beneficiary WITHOUT trust", async () => {
        var trustAddress = accounts[1];
        var beneficiaryAddress = accounts[2];
        var delayInSeconds = 60;
        var amount = web3.utils.toWei('5', 'ether');
        
        try {
            await disburse.addBeneficiarySeconds(beneficiaryAddress, delayInSeconds, amount, {from: trustAddress});
        }
        catch(err) {
            assert(true);
        }
    });

    it("can test disburse funds", async () => {

        var trustAddress = accounts[0];
        var beneficiary = accounts[1];
        var delayInSeconds = 0;
        var amount = web3.utils.toWei('2', 'ether');
        
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: trustAddress, value: weiAmount });

        await disburse.addBeneficiary(
                            beneficiary, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});

        var id = await disburse.getBeneficiaryId(beneficiary, {from: trustAddress});
        var ready = await disburse.readyToDisburse(id, { from: trustAddress});
        assert(ready);

        await disburse.disburseFunds(id, { from: trustAddress});
        var newBalance = await web3.eth.getBalance(beneficiary);
        var newETHBalance = web3.utils.fromWei(newBalance, 'ether');
        assert(newETHBalance > 100);

        // Cleanup
        await disburse.removeBeneficiary(id, {from: trustAddress});
        await disburse.withdrawTrustBalance({from: trustAddress});

        // TODO: Send balance of beneficiary back to trust
    });

    /*
    it("it can assign administrator", async () => {
        var disburse = await Disburse.deployed();
        var admin = await disburse.admin.call();
        assert.ok(admin.indexOf('0x' >= 0));  
    });

    it("it can setName", async () => {
        var accounts = await web3.eth.getAccounts();
        var disburse = await Disburse.deployed();
        await disburse.setName("Hello World", { from: accounts[0] });
        var name = await disburse.name.call();
        assert.ok(name == "Hello World");
    });
    */
});
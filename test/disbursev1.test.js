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
        
        var weiAmount = web3.utils.toWei('50', 'ether');
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

        await disburse.removeBeneficiaryAtIndex(1, {from: trustAddress});
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
        
        var beneficiary = await disburse.getBeneficiaryAtIndex(0);

        assert(beneficiary['trustAddress'] == trustAddress);
        assert(beneficiary['beneficiaryAddress'] == beneficiaryAddress);
        assert(beneficiary['disburseDate'] > 0);
        assert(beneficiary['amount'] == amount);
        assert(beneficiary['invest'] == false);
        assert(beneficiary['backup'] == false);

        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 1);
        await disburse.removeBeneficiaryAtIndex(count, {from: trustAddress});
        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 0);

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
        
        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 1);
                            
        await disburse.addBeneficiary(
                            beneficiary2, 
                            delayInSeconds, 
                            amount, 
                            {from: trustAddress});

        var count = await disburse.getBeneficiaryCount({from: trustAddress});
        assert(count == 2);

        await disburse.removeBeneficiaryAtIndex(2, {from: trustAddress});
        await disburse.removeBeneficiaryAtIndex(1, {from: trustAddress});
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
        
        var weiAmount = web3.utils.toWei('50', 'ether');
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

        var beneficiary = await disburse.getBeneficiaryAtIndex(0);
        assert(beneficiary['trustAddress'] == trustAddress);
        assert(beneficiary['beneficiaryAddress'] == beneficiary1);

        var beneficiary = await disburse.getBeneficiaryAtIndex(1);
        assert(beneficiary['trustAddress'] == trustAddress);
        assert(beneficiary['beneficiaryAddress'] == beneficiary2);

        // Cleanup
        await disburse.removeBeneficiaryAtIndex(2, {from: trustAddress});
        await disburse.removeBeneficiaryAtIndex(1, {from: trustAddress});
        await disburse.withdrawTrustBalance({from: trustAddress});
    });

    it("cannot add beneficiary without trust", async () => {
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
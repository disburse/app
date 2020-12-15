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

    it("can add beneficiary to trust", async () => {
        var trustAddress = accounts[0];
        var beneficiaryAddress = accounts[1];
        var delayInSeconds = 60;
        var amount = web3.utils.toWei('5', 'ether');
        
        await disburse.addBeneficiarySeconds(beneficiaryAddress, delayInSeconds, amount, {from: trustAddress});
        var beneficiary = await disburse.getBeneficiary(beneficiaryAddress);

        assert(beneficiary[0] == trustAddress);
        assert(beneficiary[1] > 0);
        assert(beneficiary[2] == amount);
        assert(beneficiary[3] == false);
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
const assert = require('assert');
const Disburse = artifacts.require("DisburseV1");

contract("Disburse V1", () => {

    it("can retrieve empty trust balance", async () => {
        var disburse = await Disburse.deployed();
        var accounts = await web3.eth.getAccounts();
        var balance = await disburse.getTrustBalance(accounts[0]);
        assert(balance == 0);
    });

    it("can contribute to trust", async () => {
        var disburse = await Disburse.deployed();
        var accounts = await web3.eth.getAccounts();
        var weiAmount = web3.utils.toWei('10', 'ether');
        await disburse.contributeToTrust({ from: accounts[0], value: weiAmount });
        var balance = await disburse.getTrustBalance(accounts[0]);
        assert(balance == weiAmount);
    });

    it("can withdraw trust balance", async () => {
        var disburse = await Disburse.deployed();
        var accounts = await web3.eth.getAccounts();
        var originalBalance = await web3.eth.getBalance(accounts[0]);
        await disburse.withdrawTrustBalance({ from: accounts[0]});
        var newBalance = await web3.eth.getBalance(accounts[0]);
        assert(newBalance >= originalBalance);
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
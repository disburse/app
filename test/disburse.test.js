const assert = require('assert');
const Disburse = artifacts.require("Disburse");

contract("Disburse", () => {

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

});
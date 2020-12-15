const assert = require("assert");

//const ganache = require("ganache-cli");
//const Web3 = require("web3");
//const web3 = new Web3(ganache.provider());
//const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'))

//Connect to local Ganache
//const provider = new Web3.providers.HttpProvider('http://localhost:8545');

describe("Network Test", () => {
    it("it can retreive the network id", async () => {
        var networkId = await web3.eth.net.getId();
        assert.ok(networkId > 0);  
    });

    it("it can retreive an account balance", async () => {
        var accounts = await web3.eth.getAccounts();
        var balance = await web3.eth.getBalance(accounts[0]);
        assert.ok(balance > 0);  
    });
});
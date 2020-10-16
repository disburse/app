const Disburse = artifacts.require("Disburse");

module.exports = function (deployer) {
  deployer.deploy(Disburse);
};

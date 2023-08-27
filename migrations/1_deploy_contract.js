const FireERC20 = artifacts.require("FireERC20");

module.exports = function(deployer) {
    deployer.deploy(FireERC20);
  };
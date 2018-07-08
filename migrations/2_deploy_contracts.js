var OracleToken = artifacts.require("./OracleToken.sol");

module.exports = function(deployer) {
  deployer.deploy(OracleToken);
};

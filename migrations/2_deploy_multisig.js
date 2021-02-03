const Multisig = artifacts.require("Multisig");

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(Multisig, {
    counter: 0,
    threshold: 0,
    pubKeys: Array(0),
  });
};

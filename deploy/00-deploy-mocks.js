const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");

const BASE_FEE = ethers.utils.parseEther("0.25"); // The BASE_FEE is the premium. It costs 0.25 per request
const GAS_PRICE_LINK = 1e9; // link per gas. calculated value based on the gas price of the chain.

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  if (developmentChains.includes(network.name)) {
    log("Local network detected! Deploying mocks...");
    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      log: true,
      args: [BASE_FEE, GAS_PRICE_LINK],
    });

    log("Mocks Deployed!");
    log("------------------------------------------------------");
  }
};

module.exports.tags = ["all", "mocks"];

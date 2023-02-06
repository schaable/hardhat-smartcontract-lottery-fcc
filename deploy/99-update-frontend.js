const { ethers, network } = require("hardhat");
const fs = require("fs");

const FRONTEND_ADDRESSES_FILE = "../nextjs-smartcontract-lottery/constants/contractAddresses.json";
const FRONTEND_ABI_FILE = "../nextjs-smartcontract-lottery/constants/abi.json";

module.exports = async function () {
  if (!process.env.UPDATE_FRONTEND) {
    return;
  }
  console.log("Updating frontend...");
  try {
    await updateContractAddresses();
    await updateAbi();
  } catch (e) {
    console.log(e);
  }
};

async function updateContractAddresses() {
  const chainId = network.config.chainId.toString();
  const raffle = await ethers.getContract("Raffle");
  const currentAddresses = JSON.parse(fs.readFileSync(FRONTEND_ADDRESSES_FILE, "utf8"));
  if (chainId in currentAddresses) {
    if (!currentAddresses[chainId].includes(raffle.address)) {
      currentAddresses[chainId].push(raffle.address);
    }
  } else {
    currentAddresses[chainId] = [raffle.address];
  }

  fs.writeFileSync(FRONTEND_ADDRESSES_FILE, JSON.stringify(currentAddresses));
}

async function updateAbi() {
  const raffle = await ethers.getContract("Raffle");
  const abi = raffle.interface.format(ethers.utils.FormatTypes.json);

  fs.writeFileSync(FRONTEND_ABI_FILE, abi);
}

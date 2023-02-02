const { assert } = require("chai");
const { network, getNamedAccounts, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

developmentChains.includes(network.name)
  ? describe.skip
  : describe("Raffle", () => {
      let raffle;
      let raffleEntranceFee;
      let deployer;

      beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer;
        raffle = await ethers.getContract("Raffle", deployer);
        raffleEntranceFee = await raffle.getEntranceFee();
      });

      describe("fulfillRandomWords", () => {
        it("works with live Chainlink Keepers and Chainlink VRF, we get a random winner", async () => {
          const startingTimestamp = await raffle.getLatestTimestamp();
          const deployerAccount = await ethers.getNamedSigner("deployer");

          await new Promise(async (resolve, reject) => {
            raffle.once("WinnerPicked", async () => {
              try {
                const recentWinner = await raffle.getRecentWinner();
                const winnerEndingBalance = await deployerAccount.getBalance();
                const raffleState = await raffle.getRaffleState();
                const endingTimestamp = await raffle.getLatestTimestamp();
                const numPlayers = await raffle.getNumberOfPlayers();

                assert.equal(numPlayers.toString(), "0"); // another way: await expect(raffle.getPlayer(0)).to.be.reverted
                assert.equal(raffleState.toString(), "0");
                assert.equal(recentWinner, deployerAccount.address);
                assert.equal(winnerEndingBalance.toString(), winnerStartingBalance.add(raffleEntranceFee).toString());
                assert(endingTimestamp > startingTimestamp);
                resolve();
              } catch (error) {
                reject(error);
              }
            });

            const tx = await raffle.enterRaffle({ value: raffleEntranceFee });
            await tx.wait(1);
            const winnerStartingBalance = await deployerAccount.getBalance();
          });
        });
      });
    });

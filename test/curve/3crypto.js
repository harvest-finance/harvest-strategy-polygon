// Utilities
const Utils = require("../utilities/Utils.js");
const {
  impersonates,
  setupCoreProtocol,
  depositVault,
  swapMaticToToken,
  addLiquidity
} = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("IERC20");

//const Strategy = artifacts.require("");
const Strategy = artifacts.require("CurveStrategy3CryptoMainnet");
const IDeposit = artifacts.require("ICurveDeposit_5token");


// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Polygon Mainnet Curve 3Crypto", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let usdc = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  let depositAddr = "0x3FCD5De6A9fC8A99995c406c77DDa3eD7E406f81";
  let deposit;

  // parties in the protocol
  let governance;
  let farmer1;

  // numbers used in tests
  let farmerBalance;

  // Core protocol contracts
  let controller;
  let vault;
  let strategy;

  async function setupExternalContracts() {
    underlying = await IERC20.at("0x8096ac61db23291252574D49f036f0f9ed8ab390");
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    token1 = await IERC20.at(usdc);
    await swapMaticToToken (
      farmer1,
      [addresses.WMATIC, token1.address],
      "1000" + "000000000000000000",
      addresses.QuickRouter
    );
    farmerToken1Balance = await token1.balanceOf(farmer1);
    deposit = await IDeposit.at(depositAddr);
    await token1.approve(depositAddr, farmerToken1Balance, { from:farmer1});
    await deposit.add_liquidity([0, farmerToken1Balance, 0, 0, 0], 0, {from:farmer1});
    farmerBalance = await underlying.balanceOf(farmer1);
  }

  before(async function() {
    governance = "0xf00dD244228F51547f0563e60bCa65a30FBF5f7f";
    accounts = await web3.eth.getAccounts();

    farmer1 = accounts[1];

    // impersonate accounts
    await impersonates([governance]);

    let etherGiver = accounts[9];
    await send.ether(etherGiver, governance, "100" + "000000000000000000")

    await setupExternalContracts();
    [controller, vault, strategy] = await setupCoreProtocol({
      "existingVaultAddress": null,
      "strategyArtifact": Strategy,
      "strategyArtifactIsUpgradable": true,
      "underlying": underlying,
      "governance": governance,
    });

    // whale send underlying to farmers
    await setupBalance();
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      await depositVault(farmer1, underlying, vault, farmerBalance);

      // Using half days is to simulate how we doHardwork in the real world
      // The rewards are time based and Hardhat propagates the chain with a block time of 16s
      // So we have 225 blocks per hour, 2700 blocks per 12 hours.
      let hours = 10;
      let blocksPerHour = 2700;
      let oldSharePrice;
      let newSharePrice;
      for (let i = 0; i < hours; i++) {
        console.log("loop ", i);

        oldSharePrice = new BigNumber(await vault.getPricePerFullShare());
        await controller.doHardWork(vault.address, { from: governance });
        newSharePrice = new BigNumber(await vault.getPricePerFullShare());

        console.log("old shareprice: ", oldSharePrice.toFixed());
        console.log("new shareprice: ", newSharePrice.toFixed());
        console.log("growth: ", newSharePrice.toFixed() / oldSharePrice.toFixed());

        await Utils.advanceNBlock(blocksPerHour);
      }
      await vault.withdraw(new BigNumber(await vault.balanceOf(farmer1)).toFixed(), { from: farmer1 });
      let farmerNewBalance = new BigNumber(await underlying.balanceOf(farmer1));
      Utils.assertBNGt(farmerNewBalance, farmerOldBalance);

      apr = (farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/225))*365;
      apy = ((farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/225))+1)**365;

      console.log("earned!");
      console.log("APR:", apr*100, "%");
      console.log("APY:", (apy-1)*100, "%");

      await strategy.withdrawAllToVault({from:governance}); // making sure can withdraw all for a next switch

    });
  });
});

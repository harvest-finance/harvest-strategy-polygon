// Utilities
const Utils = require("../utilities/Utils.js");
const {
  impersonates,
  setupCoreProtocol,
  depositVault,
  swapMaticToToken,
  addLiquidity,
  wrapMATIC
} = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("IERC20");
const WMATIC = artifacts.require("WMATIC");

//const Strategy = artifacts.require("");
const Strategy = artifacts.require("BalancerStrategyMainnet_TUSD_STABLE");

// Developed and tested at blockNumber 18886915

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Polygon Mainnet Balancer TUSD Stable", function() {
  let accounts;

  // external contracts
  let underlying;
  let bal;
  let tusd;
  let wmatic;

  // external setup
  let underlyingWhale = "0x879CE8cd44ba2873773E4A9fa0D768b8A3FFB88D";
  let balHolder = "0xc79dF9fe252Ac55AF8aECc3D93D20b6A4A84527B";
  let balAddr = "0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3";
  let tusdAddr = "0x2e1ad108ff1d8c782fcbbb89aad783ac49586756";
  let tusdHolder = "0x879CE8cd44ba2873773E4A9fa0D768b8A3FFB88D";

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
    underlying = await IERC20.at("0x0d34e5dD4D8f043557145598E4e2dC286B35FD4f");
    bal = await IERC20.at(balAddr);
    tusd = await IERC20.at(tusdAddr);
    wmatic = await WMATIC.at(addresses.WMATIC);
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    let etherGiver = accounts[9];
    await send.ether(etherGiver, underlyingWhale, "1" + "000000000000000000");

    farmerBalance = await underlying.balanceOf(underlyingWhale);
    await underlying.transfer(farmer1, farmerBalance, { from: underlyingWhale });
  }

  before(async function() {
    governance = "0xf00dD244228F51547f0563e60bCa65a30FBF5f7f";
    accounts = await web3.eth.getAccounts();

    farmer1 = accounts[1];

    // impersonate accounts
    await impersonates([governance, underlyingWhale, balHolder, tusdHolder]);

    let etherGiver = accounts[9];
    await send.ether(etherGiver, governance, "100" + "000000000000000000");
    await send.ether(etherGiver, balHolder, "100" + "000000000000000000");
    await send.ether(etherGiver, tusdHolder, "100" + "000000000000000000");

    await setupExternalContracts();
    [controller, vault, strategy] = await setupCoreProtocol({
      "existingVaultAddress": null,
      "strategyArtifact": Strategy,
      "strategyArtifactIsUpgradable": true,
      "underlying": underlying,
      "governance": governance,
    });

    await strategy.setSellFloor(1, {from:governance});

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

        await bal.transfer(strategy.address, "100" + "000000000000000000", {from: balHolder});
        await tusd.transfer(strategy.address, "100" + "000000000000000000", {from: tusdHolder});
        await wmatic.deposit({from: accounts[9], value: "100" + "000000000000000000"});
        await wmatic.transfer(strategy.address, "100" + "000000000000000000", {from: accounts[9]});

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

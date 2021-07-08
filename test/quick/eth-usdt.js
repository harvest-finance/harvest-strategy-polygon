// Utilities
const addresses = require("../test-config.js");
const Utils = require("../utilities/Utils.js");
const {
  impersonates,
  setupCoreProtocol,
  depositVault,
  swapMaticToToken,
  addLiquidity
} = require("../utilities/hh-utils.js");

const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("IERC20");

const Strategy = artifacts.require("QuickStrategyMainnet_ETH_USDT");

describe("Matic ETH/USDT", function() {
  let accounts;
  let underlying;

  // external setup
  let token0Addr = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  let token1Addr = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";

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
    underlying = await IERC20.at("0xF6422B997c7F54D1c6a6e103bcb1499EeA0a7046");
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    token0 = await IERC20.at(token0Addr);
    token1 = await IERC20.at(token1Addr);
    await swapMaticToToken (
      farmer1,
      [addresses.WMATIC, token0.address],
      "1000" + "000000000000000000",
      addresses.QuickRouter
    );
    farmerToken0Balance = await token0.balanceOf(farmer1);

    await swapMaticToToken (
      farmer1,
      [addresses.WMATIC, token0.address, token1.address],
      "1000" + "000000000000000000",
      addresses.QuickRouter
    );
    farmerToken1Balance = await token1.balanceOf(farmer1);

    await addLiquidity (
      farmer1,
      token0,
      token1,
      farmerToken0Balance,
      farmerToken1Balance,
      addresses.QuickRouter
    );
    farmerBalance = await underlying.balanceOf(farmer1);
    console.log(new BigNumber(farmerBalance).toFixed());
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
      "underlying": underlying,
      "governance": governance,
    });

    await strategy.setSellFloor(0, {from:governance});

    // whale send underlying to farmers
    await setupBalance();
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      await depositVault(farmer1, underlying, vault, farmerBalance);

      let farmerVaultShare = new BigNumber(await vault.balanceOf(farmer1)).toFixed();
      let vaultERC20 = await IERC20.at(vault.address);

      // Using half days is to simulate how we doHardwork in the real world
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

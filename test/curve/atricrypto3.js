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
const Strategy = artifacts.require("CurveStrategyAcricrypto3Mainnet");
const IDeposit = artifacts.require("ICurveDeposit_5token");

// test run with block number: 25091822

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Polygon Mainnet Curve atricrypto3", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let usdt = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";
  let depositAddr = "0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8";
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
    underlying = await IERC20.at("0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3");
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    token1 = await IERC20.at(usdt);
    await swapMaticToToken (
      farmer1,
      [addresses.WMATIC, token1.address],
      "1000" + "000000000000000000",
      addresses.QuickRouter
    );
    farmerToken1Balance = await token1.balanceOf(farmer1);
    console.log("farmerToken1Balance:", new BigNumber(farmerToken1Balance).toFixed());
    deposit = await IDeposit.at(depositAddr);
    await token1.approve(depositAddr, farmerToken1Balance, { from:farmer1});
    await deposit.add_liquidity([0, 0, farmerToken1Balance, 0, 0], 0, {from:farmer1});
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

    await strategy.setSellFloor(0, {from:governance});

    // whale send underlying to farmers
    await setupBalance();
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      await depositVault(farmer1, underlying, vault, farmerBalance);

      // Using half days is to simulate how we doHardwork in the real world
      // The rewards are time based and polygon network has according to https://polygonscan.com/chart/blocks
      // 30'000 to 41'000 blocks per day, lets assume 35'00 blocks per day therefore we have about 1500 blocks per hour (35'000 / 24= ~1459)
      // therfore we have 12*1500 = 18'000 blocks per 12 hours
      let hours = 10;
      let blocksPerHour = 12*1500;
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

      apr = (farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1500))*365;
      apy = ((farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1500))+1)**365;

      console.log("earned!");
      console.log("APR:", apr*100, "%");
      console.log("APY:", (apy-1)*100, "%");

      await strategy.withdrawAllToVault({from:governance}); // making sure can withdraw all for a next switch

    });
  });
});

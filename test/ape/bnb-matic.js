// Utilities
const Utils = require("../utilities/Utils.js");
const {
  impersonates,
  setupCoreProtocol,
  depositVault,
  swapMaticToToken,
  wrapMATIC,
  addLiquidity
} = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("IERC20");

//const Strategy = artifacts.require("");
const Strategy = artifacts.require("ApeStrategyMainnet_BNB_MATIC");
const FeeRewardForwarder = artifacts.require("FeeRewardForwarder");

const apeRouterAddress = "0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607";

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Polygon Mainnet ApeSwap BNB/MATIC", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let token0Addr = "0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F"; //bnb
  let token1Addr = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"; //wmatic
  let feeForwarderAddr = "0x9A56E4e1845b021FE63EBCE922bD1c31e87eEA5A";
  let banana = "0x5d47bAbA0d66083C52009271faF3F50DCc01023C";
  let weth = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";


  // parties in the protocol
  let governance;
  let farmer1;

  // numbers used in tests
  let farmerBalance;

  // Core protocol contracts
  let controller;
  let vault;
  let strategy;
  let token0;
  let farmerToken0Balance;
  let token1;
  let farmerToken1Balance;

  async function setupExternalContracts() {
    underlying = await IERC20.at("0x0359001070cF696D5993E0697335157a6f7dB289"); //bnb-matic
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    token0 = await IERC20.at(token0Addr);
    token1 = await IERC20.at(token1Addr);
    
    await swapMaticToToken (
      farmer1,
      [addresses.WMATIC, token0.address],
      "1000" + "000000000000000000",
      apeRouterAddress
    );
    farmerToken0Balance = await token0.balanceOf(farmer1);
    
    await wrapMATIC(farmer1, "1000" + "000000000000000000");
    farmerToken1Balance = await token1.balanceOf(farmer1);
    

    await addLiquidity (
      farmer1,
      token0,
      token1,
      farmerToken0Balance,
      farmerToken1Balance,
      apeRouterAddress
    );
    farmerBalance = await underlying.balanceOf(farmer1);

    console.log("farmerBalance: ");
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
      "strategyArtifactIsUpgradable": true
    });

    feeForwarder = await FeeRewardForwarder.at(feeForwarderAddr);
    let path = [banana, token1Addr, weth];
    let dexes = [apeRouterAddress];
    await feeForwarder.setConversionPath(path, dexes, { from: governance });

    await strategy.setSellFloor(0, {from:governance});

    // whale send underlying to farmers
    await setupBalance();
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      await depositVault(farmer1, underlying, vault, farmerBalance);

      // Using half days is to simulate how we doHardwork in the real world
      let hours = 10;
      let blocksPerHour = 1565*5;
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

      apr = (farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1565))*365;
      apy = ((farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1565))+1)**365;

      console.log("earned!");
      console.log("APR:", apr*100, "%");
      console.log("APY:", (apy-1)*100, "%");

      await strategy.withdrawAllToVault({from:governance}); // making sure can withdraw all for a next switch

    });
  });
});

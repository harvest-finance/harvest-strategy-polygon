// Utilities
const Utils = require("../utilities/Utils.js");
const { impersonates, setupCoreProtocol, depositVault } = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20");

const HodlStrategy = artifacts.require("JarvisStrategyMainnet_AUR_USDC");
const Strategy = artifacts.require("JarvisHodlStrategyMainnet_jCHF_USDC");
const FeeRewardForwarder = artifacts.require("FeeRewardForwarder");

const D18 = new BigNumber(Math.pow(10, 18));

//This test was developed at blockNumber 20192005

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Mainnet Jarvis jCHF-USDC HODL in LP", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let underlyingWhale = "0x309f38Fe245c900e011e3405c65e6b28F02F65ec";
  let usdc = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  let weth = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  let feeForwarderAddr = "0x9A56E4e1845b021FE63EBCE922bD1c31e87eEA5A";
  let quickRouter = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff";
  let hodlUnderlying = "0xA0fB4487c0935f01cBf9F0274FE3CdB21a965340";

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
    underlying = await IERC20.at("0x439E6A13a5ce7FdCA2CC03bF31Fb631b3f5EF157");
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    let etherGiver = accounts[9];
    // Give whale some ether to make sure the following actions are good
    await web3.eth.sendTransaction({ from: etherGiver, to: underlyingWhale, value: 1e18});

    farmerBalance = await underlying.balanceOf(underlyingWhale);
    await underlying.transfer(farmer1, farmerBalance, { from: underlyingWhale });
  }

  before(async function() {
    governance = "0xf00dD244228F51547f0563e60bCa65a30FBF5f7f";
    accounts = await web3.eth.getAccounts();

    farmer1 = accounts[1];

    // impersonate accounts
    await impersonates([governance, underlyingWhale]);

    await setupExternalContracts();
    [controller, hodlVault, hodlStrategy] = await setupCoreProtocol({
      "existingVaultAddress": null,
      "strategyArtifact": HodlStrategy,
      "strategyArtifactIsUpgradable": true,
      "underlying": await IERC20.at(hodlUnderlying),
      "governance": governance,
    });
    [controller, vault, strategy, potPool] = await setupCoreProtocol({
      "existingVaultAddress": null,
      "strategyArtifact": Strategy,
      "strategyArtifactIsUpgradable": true,
      "underlying": underlying,
      "governance": governance,
      "rewardPool" : true,
      "rewardPoolConfig": {
        type: 'PotPool',
        rewardTokens: [
          hodlVault.address // fAUR-USDC
        ]
      },
    });

    feeForwarder = await FeeRewardForwarder.at(feeForwarderAddr);
    let path = [usdc, weth];
    let dexes = [quickRouter];
    await feeForwarder.setConversionPath(path, dexes, { from: governance });

    await strategy.setHodlVault(hodlVault.address, {from: governance});
    await strategy.setPotPool(potPool.address, {from: governance});
    await potPool.setRewardDistribution([strategy.address], true, {from: governance});
    // await controller.addToWhitelist(strategy.address, {from: governance});

    // whale send underlying to farmers
    await setupBalance();
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      let farmerOldfAUR_USDC = new BigNumber(await hodlVault.balanceOf(farmer1));
      await depositVault(farmer1, underlying, vault, farmerBalance);
      let fTokenBalance = new BigNumber(await vault.balanceOf(farmer1));

      let erc20Vault = await IERC20.at(vault.address);
      await erc20Vault.approve(potPool.address, fTokenBalance, {from: farmer1});
      await potPool.stake(fTokenBalance, {from: farmer1});

      // Using half days is to simulate how we doHardwork in the real world
      let hours = 10;
      let blocksPerHour = 2400;
      let oldSharePrice;
      let newSharePrice;
      let oldHodlSharePrice;
      let newHodlSharePrice;
      let oldPotPoolBalance;
      let newPotPoolBalance;
      let hodlPrice;
      let lpPrice;
      let oldValue;
      let newValue;
      for (let i = 0; i < hours; i++) {
        console.log("loop ", i);

        oldSharePrice = new BigNumber(await vault.getPricePerFullShare());
        oldHodlSharePrice = new BigNumber(await hodlVault.getPricePerFullShare());
        oldPotPoolBalance = new BigNumber(await hodlVault.balanceOf(potPool.address));
        await controller.doHardWork(vault.address, {from: governance});
        await controller.doHardWork(hodlVault.address, {from: governance});
        newSharePrice = new BigNumber(await vault.getPricePerFullShare());
        newHodlSharePrice = new BigNumber(await hodlVault.getPricePerFullShare());
        newPotPoolBalance = new BigNumber(await hodlVault.balanceOf(potPool.address));

        hodlPrice = new BigNumber(134051798.60).times(D18);
        lpPrice = new BigNumber(2088601.44).times(D18);
        console.log("Hodl price:", hodlPrice.toFixed()/D18.toFixed());
        console.log("LP price:", lpPrice.toFixed()/D18.toFixed());

        oldValue = (fTokenBalance.times(oldSharePrice).times(lpPrice)).div(1e36).plus((oldPotPoolBalance.times(oldHodlSharePrice).times(hodlPrice)).div(1e36));
        newValue = (fTokenBalance.times(newSharePrice).times(lpPrice)).div(1e36).plus((newPotPoolBalance.times(newHodlSharePrice).times(hodlPrice)).div(1e36));

        console.log("old value: ", oldValue.toFixed()/D18.toFixed());
        console.log("new value: ", newValue.toFixed()/D18.toFixed());
        console.log("growth: ", newValue.toFixed() / oldValue.toFixed());

        console.log("fAUR-USDC in potpool: ", newPotPoolBalance.toFixed());

        apr = (newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour/1565))*365;
        apy = ((newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour/1565))+1)**365;

        console.log("instant APR:", apr*100, "%");
        console.log("instant APY:", (apy-1)*100, "%");

        await Utils.advanceNBlock(blocksPerHour);
      }
      // withdrawAll to make sure no doHardwork is called when we do withdraw later.
      await vault.withdrawAll({ from: governance });

      // wait until all reward can be claimed by the farmer
      await Utils.waitTime(86400 * 30 * 1000);
      console.log("vaultBalance: ", fTokenBalance.toFixed());
      await potPool.exit({from: farmer1});
      await vault.withdraw(fTokenBalance.toFixed(), { from: farmer1 });
      let farmerNewBalance = new BigNumber(await underlying.balanceOf(farmer1));
      let farmerNewfAUR_USDC = new BigNumber(await hodlVault.balanceOf(farmer1));
      Utils.assertBNEq(farmerNewBalance, farmerOldBalance);
      Utils.assertBNGt(farmerNewfAUR_USDC, farmerOldfAUR_USDC);

      oldValue = (fTokenBalance.times(1e18).times(lpPrice)).div(1e36);
      newValue = (fTokenBalance.times(newSharePrice).times(lpPrice)).div(1e36).plus((farmerNewfAUR_USDC.times(newHodlSharePrice).times(hodlPrice)).div(1e36));

      apr = (newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour*hours/1565))*365;
      apy = ((newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour*hours/1565))+1)**365;

      console.log("Overall APR:", apr*100, "%");
      console.log("Overall APY:", (apy-1)*100, "%");

      console.log("potpool totalShare: ", (new BigNumber(await potPool.totalSupply())).toFixed());
      console.log("fAUR-USDC in potpool: ", (new BigNumber(await hodlVault.balanceOf(potPool.address))).toFixed() );
      console.log("Farmer got fAUR-USDC from potpool: ", farmerNewfAUR_USDC.toFixed());
      console.log("earned!");

      await strategy.withdrawAllToVault({ from: governance }); // making sure can withdraw all for a next switch
    });
  });
});

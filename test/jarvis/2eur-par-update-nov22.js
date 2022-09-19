// Utilities
const Utils = require("../utilities/Utils.js");
const { impersonates, setupCoreProtocol, depositVault } = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20");
const IController = artifacts.require("IController");
const Vault = artifacts.require("Vault");
const PotPool = artifacts.require("PotPool");

const Strategy = artifacts.require("JarvisHodlStrategyV3Mainnet_2EUR_PAR");

const D18 = new BigNumber(Math.pow(10, 18));

//This test was developed at blockNumber 33307200

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Mainnet Jarvis 2EUR-PAR HODL in LP - Update rewardPool", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let underlyingWhale = "0xaa8A19d6bF655Bfa3C448248ad2482D05BAb6f98";
  let vaultAddr = "0x023E85B8415b460C56377525ED159aF9935E3370";
  let potPoolAddr = "0x2892FA6e9D7Fc9bc8C8e62BBe79AdDff41314d03";
  let hodlVaultAddr = "0xF67d5e775C76E1631ea33D9977A02EccD7316a4C";

  let rewardPoolAddr = "0xeA9871A9451c281cc1180100FC074D7F28402288";
  let rewardTokenAddr = "0x4Fd52587194a0bfd3AC5b8096D15e1a7230bA2eb";
  let rewardLPAddr = "0x946bE3eCAebaA3fe2eBb73864ab555A8cfdF49Fd";
  let pid = 0;

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
    underlying = await IERC20.at("0x0f110c55EfE62c16D553A3d3464B77e1853d0e97");
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

    controller = await IController.at(addresses.Controller);
    vault = await Vault.at(vaultAddr);
    hodlVault = await Vault.at(hodlVaultAddr);
    strategy = await Strategy.at(await vault.strategy());
    potPool = await PotPool.at(potPoolAddr);

    await strategy.updateRewardPool(
      rewardPoolAddr,
      rewardTokenAddr,
      rewardLPAddr,
      pid,
      hodlVaultAddr,
      {from: governance});

    await potPool.addRewardToken(hodlVaultAddr, {from: governance});

    // whale send underlying to farmers
    await setupBalance();
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      let farmerOldHodlBalance = new BigNumber(await hodlVault.balanceOf(farmer1));
      await depositVault(farmer1, underlying, vault, farmerBalance);
      let fTokenBalance = new BigNumber(await vault.balanceOf(farmer1));

      let erc20Vault = await IERC20.at(vault.address);
      await erc20Vault.approve(potPool.address, fTokenBalance, {from: farmer1});
      await potPool.stake(fTokenBalance, {from: farmer1});

      // Using half days is to simulate how we doHardwork in the real world
      let hours = 10;
      let blocksPerHour = 1565*5;
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

        hodlPrice = new BigNumber(17.407).times(D18);
        lpPrice = new BigNumber(1.02).times(D18);
        console.log("Hodl price:", hodlPrice.toFixed()/D18.toFixed());
        console.log("LP price:", lpPrice.toFixed()/D18.toFixed());

        oldValue = (fTokenBalance.times(oldSharePrice).times(lpPrice)).div(1e36).plus((oldPotPoolBalance.times(oldHodlSharePrice).times(hodlPrice)).div(1e36));
        newValue = (fTokenBalance.times(newSharePrice).times(lpPrice)).div(1e36).plus((newPotPoolBalance.times(newHodlSharePrice).times(hodlPrice)).div(1e36));

        console.log("old value: ", oldValue.toFixed()/D18.toFixed());
        console.log("new value: ", newValue.toFixed()/D18.toFixed());
        console.log("growth: ", newValue.toFixed() / oldValue.toFixed());

        console.log("HodlToken in potpool: ", newPotPoolBalance.toFixed());

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
      let farmerNewHodlBalance = new BigNumber(await hodlVault.balanceOf(farmer1));
      Utils.assertBNGte(farmerNewBalance, farmerOldBalance);
      Utils.assertBNGt(farmerNewHodlBalance, farmerOldHodlBalance);

      oldValue = (fTokenBalance.times(1e18).times(lpPrice)).div(1e36);
      newValue = (fTokenBalance.times(newSharePrice).times(lpPrice)).div(1e36).plus((farmerNewHodlBalance.times(newHodlSharePrice).times(hodlPrice)).div(1e36));

      apr = (newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour*hours/1565))*365;
      apy = ((newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour*hours/1565))+1)**365;

      console.log("Overall APR:", apr*100, "%");
      console.log("Overall APY:", (apy-1)*100, "%");

      console.log("potpool totalShare: ", (new BigNumber(await potPool.totalSupply())).toFixed());
      console.log("HodlToken in potpool: ", (new BigNumber(await hodlVault.balanceOf(potPool.address))).toFixed() );
      console.log("Farmer got HodlToken from potpool: ", farmerNewHodlBalance.toFixed());
      console.log("earned!");

      await strategy.withdrawAllToVault({ from: governance }); // making sure can withdraw all for a next switch
    });
  });
});

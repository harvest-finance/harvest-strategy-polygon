// Utilities
const Utils = require("../utilities/Utils.js");
const { impersonates, setupCoreProtocol, depositVault } = require("../utilities/hh-utils.js");

const addresses = require("../../../matic-config/matic-addresses.json");
const { send, expectRevert, time } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20Upgradeable = artifacts.require("IERC20Upgradeable");

const Storage = artifacts.require("Storage");
const NotifyHelperStateful = artifacts.require("NotifyHelperStateful");
const NotifyHelperGeneric = artifacts.require("NotifyHelperGeneric");
const GlobalIncentivesHelper = artifacts.require("GlobalIncentivesHelper");
const Governable = artifacts.require("Governable");
const Controllable = artifacts.require("Controllable");
const PotPool = artifacts.require("PotPool");


// block 21829169
describe("Emission tests", function() {
  let accounts;

  let storage = addresses.Storage;
  let governance = addresses.GOVERNANCE;
  let notifyHelperRegular;
  let nobody;

  let usdcEurHolder = "0x08ac9c15aaf98563a4b19ddbd0153ff3516d65a8";
  let usdcGbpHolder = "0x420674a75e1e158a3c675f13df1f26d51f22b502";
  let usdcEurContract;
  let usdcGbpContract;

  let NotificationType = {
      VOID : 0, AMPLIFARM : 1, FARM : 2, TRANSFER : 3, PROFIT_SHARE : 4, TOKEN: 5
  }

  // contracts
  let miFARM;
  let statefulHelper;
  let helperStorage;
  let globalIncentivesHelper;

  let emission = [
    {
      address: "0xf25474FBf9812bE2ef76abf4297A27411C156403", // Jarvis: EUR-USDC
      percentage: "1"
    },
    {
      address: "0x877635e68C1E943D6d6B777C0e847Cd7aE5A01BE", // Jarvis: GBP-USDC
      percentage: "2"
    },
  ]
  let emissionMatic = [
    {
      address: "0xf25474FBf9812bE2ef76abf4297A27411C156403", // Jarvis: EUR-USDC
      percentage: "1"
    },
    {
      address: "0x877635e68C1E943D6d6B777C0e847Cd7aE5A01BE", // Jarvis: GBP-USDC
      percentage: "2"
    },
  ]

  async function setupExternalContracts() {
    miFARM = await IERC20Upgradeable.at(addresses.miFARM);
    wMATIC = await IERC20Upgradeable.at(addresses.WMATIC);
  }

  async function setupBalance() {
    let etherGiver = accounts[9];

    let usdcEur = "0xa832926e3f6a3339ae68f70d76860d212959e0e7";
    let usdcGbp = "0xe94D89243a7Aeaf88857461ce555caEB344765Fc";

    usdcEurContract = await IERC20Upgradeable.at(usdcEur);
    usdcGbpContract = await IERC20Upgradeable.at(usdcGbp);
    await usdcEurContract.transfer(nobody, await usdcEurContract.balanceOf(usdcEurHolder), {from: usdcEurHolder});
    await usdcGbpContract.transfer(nobody, await usdcGbpContract.balanceOf(usdcGbpHolder), {from: usdcGbpHolder});
  }

  before(async function() {
    accounts = await web3.eth.getAccounts();
    nobody = accounts[7];
    await setupExternalContracts();

    // impersonate accounts
    await impersonates([governance, usdcEurHolder, usdcGbpHolder]);
    await setupBalance();

    // set the governance
    notifyHelperRegular = await NotifyHelperGeneric.new(storage);
    statefulHelper = await NotifyHelperStateful.new(storage,
      notifyHelperRegular.address,
      addresses.miFARM,
      notifyHelperRegular.address,
      "0xFEd53aA679C2C1948473A08202f6203EBDA20FD6",
      "0xd00FCE4966821Da1EdD1221a02aF0AFc876365e4");

    helperStorage = await Storage.new({from: governance});
    await notifyHelperRegular.setWhitelist(statefulHelper.address, {from : governance});

    // whitelist generic helper on the pools
    for (let i = 0; i < emission.length; i++) {
      let pool = emission[i];
      let poolContract = await PotPool.at(pool.address);
      await poolContract.setRewardDistribution([notifyHelperRegular.address], true, {from: governance});
    }

    globalIncentivesHelper = await GlobalIncentivesHelper.new(storage, addresses.miFARM, statefulHelper.address, notifyHelperRegular.address,
      "0xFEd53aA679C2C1948473A08202f6203EBDA20FD6",
      "0xd00FCE4966821Da1EdD1221a02aF0AFc876365e4");
    await notifyHelperRegular.setWhitelist(globalIncentivesHelper.address, true, {from: governance});
    await globalIncentivesHelper.newToken(addresses.WMATIC, {from: governance});

    // link the references
    await statefulHelper.setNotifier(globalIncentivesHelper.address, true, {from: governance});
    await statefulHelper.setChanger(globalIncentivesHelper.address, true, {from: governance});
    await globalIncentivesHelper.setChanger(governance, true, {from: governance});
    await globalIncentivesHelper.setNotifier(governance, true, {from: governance});
  });

  describe.only("Happy Path with assertions", function() {
    it("Configure emission for two pot pools", async function() {
      let tokens = [];
      let pools = [];
      let percentages = [];
      let types = [];
      let vesting = [];
      for (let i = 0; i < emission.length; i++) {
        let pool = emission[i];
        tokens.push(addresses.miFARM);
        pools.push(pool.address);
        percentages.push(pool.percentage);
        types.push(NotificationType.FARM);
        vesting.push(false);
      }
      for (let i = 0; i < emissionMatic.length; i++) {
        let pool = emissionMatic[i];
        tokens.push(addresses.WMATIC);
        pools.push(pool.address);
        percentages.push(pool.percentage);
        types.push(NotificationType.TOKEN);
        vesting.push(false);
      }
      console.log(tokens, pools, percentages, types, vesting);
      await globalIncentivesHelper.setPoolBatch(tokens, pools, percentages, types, vesting, {from: governance});

      assert.notEqual(
        await globalIncentivesHelper.tokenToHelper(wMATIC.address),
        await globalIncentivesHelper.tokenToHelper(miFARM.address)
      );

      // user nobody stakes
      let gbpPool = await PotPool.at("0x877635e68C1E943D6d6B777C0e847Cd7aE5A01BE");
      let eurPool = await PotPool.at("0xf25474FBf9812bE2ef76abf4297A27411C156403");
      await usdcEurContract.approve(eurPool.address, await usdcEurContract.balanceOf(nobody), {from: nobody});
      await usdcGbpContract.approve(gbpPool.address, await usdcGbpContract.balanceOf(nobody), {from: nobody});
      await gbpPool.stake(await usdcGbpContract.balanceOf(nobody), {from: nobody});
      await eurPool.stake(await usdcEurContract.balanceOf(nobody), {from: nobody});

      await miFARM.transfer(globalIncentivesHelper.address, "50" + "0".repeat(18), {from: governance});
      await wMATIC.transfer(globalIncentivesHelper.address, "120" + "0".repeat(18), {from: governance});
      await globalIncentivesHelper.notifyPools([addresses.miFARM, addresses.WMATIC], ["30" + "0".repeat(18), "60" + "0".repeat(18)], "1637694000")

      assert.equal(await miFARM.balanceOf(gbpPool.address), "20" + "0".repeat(18));
      assert.equal(await wMATIC.balanceOf(gbpPool.address), "40" + "0".repeat(18));
      assert.equal(await miFARM.balanceOf(eurPool.address), "10" + "0".repeat(18));
      assert.equal(await wMATIC.balanceOf(eurPool.address), "20" + "0".repeat(18));
      assert.equal(await miFARM.balanceOf(globalIncentivesHelper.address), "20" + "0".repeat(18));
      assert.equal(await wMATIC.balanceOf(globalIncentivesHelper.address), "60" + "0".repeat(18));

      assert.notEqual(await gbpPool.rewardRateForToken(miFARM.address), "0");
      assert.notEqual(await gbpPool.rewardRateForToken(wMATIC.address), "0");
      assert.notEqual(await eurPool.rewardRateForToken(miFARM.address), "0");
      assert.notEqual(await eurPool.rewardRateForToken(wMATIC.address), "0");

      // mind blank transactions to increase the time
      await time.increase(time.duration.days(8));
      await time.advanceBlock();

//      assert.equal(await gbpPool.earned(miFARM.address, nobody), "20" + "0".repeat(18));
//      assert.equal(await gbpPool.earned(wMATIC.address, nobody), "40" + "0".repeat(18));
//      assert.equal(await eurPool.earned(miFARM.address, nobody), "10" + "0".repeat(18));
//      assert.equal(await eurPool.earned(wMATIC.address, nobody), "20" + "0".repeat(18));

      await gbpPool.exit({from: nobody});
      await eurPool.exit({from: nobody});

      console.log(new BigNumber(await miFARM.balanceOf(nobody)).toFixed());
      console.log(new BigNumber(await wMATIC.balanceOf(nobody)).toFixed());
      assert.equal(await miFARM.balanceOf(nobody), "30" + "0".repeat(18));
      assert.equal(await wMATIC.balanceOf(nobody), "60" + "0".repeat(18));

    });

  });
});

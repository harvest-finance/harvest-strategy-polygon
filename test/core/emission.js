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

describe("Emission tests", function() {
  let accounts;

  let storage = addresses.Storage;
  let governance = addresses.GOVERNANCE;
  let bridge = "0x0b2c3d2709900db4a73055c2150d346dd54cb427";
  let notifyHelperRegular;

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
      address: addresses.V2.quickswap_IFARM_QUICK.NewPool,
      percentage: "2"
    },
    {
      address: addresses.V2.quickswap_ETH_USDT.NewPool,
      percentage: "1"
    },
    {
      address: addresses.V2.sushiswap_USDC_ETH.NewPool,
      percentage: "2"
    },
    {
      address: addresses.V2.balancer_STABLE.NewPool,
      percentage: "3"
    },
    {
      address: addresses.V2.balancer_TRICRYPTO.NewPool,
      percentage: "2"
    },
    {
      address: addresses.V2.balancer_POLYBASE.NewPool,
      percentage: "3"
    },
    {
      address: addresses.V2.jarvis_AUR_USDC.NewPool,
      percentage: "2"
    },
    {
      address: addresses.V2.jarvis_JCHF_USDC_HODL.NewPool,
      percentage: "2"
    },
    {
      address: addresses.V2.jarvis_JEUR_USDC_HODL.NewPool,
      percentage: "2"
    },
    {
      address: addresses.V2.jarvis_JGBP_USDC_HODL.NewPool,
      percentage: "2"
    },

  ]
  let emissionMatic = [
      {
        address: addresses.V2.balancer_STABLE.NewPool,
        percentage: "3"
      },
      {
        address: addresses.V2.balancer_TRICRYPTO.NewPool,
        percentage: "2"
      },
      {
        address: addresses.V2.balancer_POLYBASE.NewPool,
        percentage: "3"
      },
      {
        address: addresses.V2.jarvis_AUR_USDC.NewPool,
        percentage: "2"
      },
      {
        address: addresses.V2.jarvis_JCHF_USDC_HODL.NewPool,
        percentage: "2"
      },
      {
        address: addresses.V2.jarvis_JEUR_USDC_HODL.NewPool,
        percentage: "2"
      },
      {
        address: addresses.V2.jarvis_JGBP_USDC_HODL.NewPool,
        percentage: "2"
      },

    ]

  async function setupExternalContracts() {
    miFARM = await IERC20Upgradeable.at(addresses.miFARM);
    wMATIC = await IERC20Upgradeable.at(addresses.WMATIC);
  }

  async function setupBalance() {
    let etherGiver = accounts[9];
    // Give whale some ether to make sure the following actions are good
    await send.ether(etherGiver, underlyingWhale, "1" + "000000000000000000");
    await send.ether(etherGiver, bridge, "1" + "000000000000000000");

    farmerBalance = "1000" + "0".repeat(6);
    await underlying.transfer(farmer, farmerBalance, {from: underlyingWhale});
  }

  before(async function() {
    accounts = await web3.eth.getAccounts();
    let nobody = accounts[7];
    await setupExternalContracts();
    await send.ether(nobody, bridge, "1" + "000000000000000000");

    // impersonate accounts
    await impersonates([governance, bridge]);

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

  describe.only("Happy Path with math", function() {
    it("Configure emission", async function() {
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

      let config = await statefulHelper.getConfig("50" + "0".repeat(18));
      for (let i = 0; i < config[0].length; i++) {
        console.log(config[0][i]);
        console.log(config[1][i].toString());
        console.log(config[2][i].toString());
        console.log("");
      }

      await miFARM.approve(globalIncentivesHelper.address, "50" + "0".repeat(18), {from: governance});
      await miFARM.transfer(governance, "50" + "0".repeat(18), {from: bridge});
      await wMATIC.approve(globalIncentivesHelper.address, "50" + "0".repeat(18), {from: governance});
      await globalIncentivesHelper.notifyPools([addresses.miFARM, addresses.WMATIC], ["50" + "0".repeat(18), "50" + "0".repeat(18)], "1637694000")

    });

  });
});

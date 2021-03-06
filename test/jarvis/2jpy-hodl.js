// Utilities
const Utils = require("../utilities/Utils.js");
const { impersonates, setupCoreProtocol, depositVault } = require("../utilities/hh-utils.js");

const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20");

const HodlStrategy = artifacts.require("JarvisStrategyV3Mainnet_SES_2JPY");
const Strategy = artifacts.require("JarvisHodlStrategyV3Mainnet_2JPY");
const CurvePool = artifacts.require("ICurveDeposit_2token");
const IDMMPool = artifacts.require("IDMMPool");

const D18 = new BigNumber(Math.pow(10, 18));

//This test was developed at blockNumber 24170621

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Mainnet Jarvis 2JPY HODL in LP", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let underlyingWhale = "0xc91faf934708a5e3b3ff8ed212904c4efd2aaf57";
  let hodlUnderlying = "0x3b76F90A8ab3EA7f0EA717F34ec65d194E5e9737";
  let curvePoolAddr = "0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A";

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
    underlying = await IERC20.at("0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A");
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    let etherGiver = accounts[9];
    // Give whale some ether to make sure the following actions are good
    await web3.eth.sendTransaction({ from: etherGiver, to: underlyingWhale, value: 1e18});

    farmerBalance = await underlying.balanceOf(underlyingWhale);
    console.log("underlyingWhale balance: ", new BigNumber(farmerBalance).toFixed());
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
          hodlVault.address // fSES-2JPY
        ]
      },
    });

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
      console.log("farmerOldBalance: ", farmerOldBalance.toFixed());
      let farmerOldfSES_2JPY = new BigNumber(await hodlVault.balanceOf(farmer1));
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
      let curvePool;
      let dmmPool;

      curvePool = await CurvePool.at(curvePoolAddr);
      lpPrice = new BigNumber(await curvePool.get_virtual_price());
      hodlPrice = new BigNumber(119.387).times(D18);
      dmmPool = await IDMMPool.at(hodlUnderlying);
      console.log("total supply of DMM pool lp tokens: ", new BigNumber(await dmmPool.totalSupply()).toFixed());

      const tradeInfo = await dmmPool.getTradeInfo();
      var {0: reserve0, 1: reserve1, 2: vReserve0, 3: vReserve1, 4: feeInPrecision} = tradeInfo;

      // token0: Sestertius (SES-FEB22)
      // token1: Curve.fi Factory Plain Pool: 2jpy (2jpy-f)

      console.log("DMM pool reserve0: ", new BigNumber(reserve0).toFixed());
      console.log("DMM pool reserve1: ", new BigNumber(reserve1).toFixed());
      console.log("DMM pool vReserve0: ", new BigNumber(vReserve0).toFixed());
      console.log("DMM pool vReserve1: ", new BigNumber(vReserve1).toFixed());

      // 1 SES-FEB22 = 66220 2jpy-f from https://kyberswap.com/#/add/0x9120ECada8dc70Dc62cBD49f58e861a09bf83788/0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A/0x3b76F90A8ab3EA7f0EA717F34ec65d194E5e9737 (02.02.2022)
      console.log("Exchange rate: ", new BigNumber(vReserve1).div(new BigNumber(vReserve0)).toFixed() );

      // all pool SES-FEB22 tokens in 2jpy-f value
      let token0Amount = (new BigNumber(reserve0).toFixed()/D18.toFixed());
      console.log("token0Amount: ", token0Amount);

      let token1Amount = (new BigNumber(reserve1).toFixed()/D18.toFixed());
      console.log("token1Amount: ", token1Amount)

      let lpTokenAmount = new BigNumber(await dmmPool.totalSupply()).toFixed()/D18.toFixed();
      console.log("lpTokenAmount: ", lpTokenAmount);

      let token0inToken1Value = token0Amount*(new BigNumber(vReserve1).div(new BigNumber(vReserve0)).toFixed())
      console.log("pool SES-FEB22 tokens in 2jpy-f unit: ", token0inToken1Value);
      hodlPriceNew = ((token0inToken1Value + token1Amount) * (lpPrice.toFixed()/D18.toFixed())) / lpTokenAmount;

      console.log("hodlPriceNew: ", hodlPriceNew);
      
      hodlPrice = new BigNumber(hodlPriceNew).times(D18);

      console.log("Hodl price:", hodlPrice.toFixed()/D18.toFixed());
      console.log("LP price:", lpPrice.toFixed()/D18.toFixed());

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

        // https://kyberswap.com/#/pools/0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A/0x9120ECada8dc70Dc62cBD49f58e861a09bf83788

        // info about Kyber DMM pool: https://chainsecurity.com/wp-content/uploads/2021/04/ChainSecurity_KyberNetwork_DMM_Dynamic-Market-Making_Final.pdf
        // reserves use the Amplification Model. Instead of the inventory function x*y = k 
        // Kyber DMM pool uses x * y = k * a^2
        // All invariants related to swapping are based on the virtualReserves.
        // All invariants related to adding or removing liquidity are based on the values of the "traditional" reserves

        // ftokenBalance: amount of f2JPY of farmer1
        // oldSharePrice: vault (f2JPY strategy) share price: underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
        // lpPrice (underlying of f2JPY): price of 2jpy in virtual price of curve lp ("average dollar value of pool token")

        // oldPotPoolBalance: amount of fSES-2JPY that the PotPool holds
        // oldHodlSharePrice: vault (fSES-2JPY) share price: underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
        // hodlPrice (underlying of fSES-2JPY): price of KyberDMM LP SES-FEB22-2jpy in 

        // oldValue = (fTokenBalance * oldSharePrice * lpPrice) / 1e36 + (oldPotPoolBalance * oldHodlSharePrice * hodlPrice) / 1e36
        oldValue = (fTokenBalance.times(oldSharePrice).times(lpPrice)).div(1e36).plus((oldPotPoolBalance.times(oldHodlSharePrice).times(hodlPrice)).div(1e36));

        // newValue = (fTokenBalance * newSharePrice * lpPrice) / 1e36 + (newPotPoolBalance * newHodlSharePrice * hodlPrice) / 1e36
        newValue = (fTokenBalance.times(newSharePrice).times(lpPrice)).div(1e36).plus((newPotPoolBalance.times(newHodlSharePrice).times(hodlPrice)).div(1e36));

        console.log("old value: ", oldValue.toFixed()/D18.toFixed());
        console.log("new value: ", newValue.toFixed()/D18.toFixed());
        console.log("growth: ", newValue.toFixed() / oldValue.toFixed());

        console.log("fSES-JPY in potpool: ", newPotPoolBalance.toFixed());

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
      let farmerNewfSES_2JPY = new BigNumber(await hodlVault.balanceOf(farmer1));
      Utils.assertBNGte(farmerNewBalance, farmerOldBalance);
      Utils.assertBNGt(farmerNewfSES_2JPY, farmerOldfSES_2JPY);

      oldValue = (fTokenBalance.times(1e18).times(lpPrice)).div(1e36);
      newValue = (fTokenBalance.times(newSharePrice).times(lpPrice)).div(1e36).plus((farmerNewfSES_2JPY.times(newHodlSharePrice).times(hodlPrice)).div(1e36));

      apr = (newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour*hours/1565))*365;
      apy = ((newValue.toFixed()/oldValue.toFixed()-1)*(24/(blocksPerHour*hours/1565))+1)**365;

      console.log("Overall APR:", apr*100, "%");
      console.log("Overall APY:", (apy-1)*100, "%");

      console.log("potpool totalShare: ", (new BigNumber(await potPool.totalSupply())).toFixed());
      console.log("fSES-JPY in potpool: ", (new BigNumber(await hodlVault.balanceOf(potPool.address))).toFixed() );
      console.log("Farmer got fSES-JPY from potpool: ", farmerNewfSES_2JPY.toFixed());
      console.log("earned!");

      await strategy.withdrawAllToVault({ from: governance }); // making sure can withdraw all for a next switch
    });
  });
});

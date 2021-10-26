//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "./interfaces/IStakingRewardsWithPlatformToken.sol";
import "./interfaces/ISavingsContract.sol";
import "./interfaces/IBVault.sol";
import "./interfaces/IMasset.sol";

contract MStableStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant dai = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    address public constant musd = address(0xE840B73E5287865EEc17d250bFb1536704B43B21);
    address public constant imUSD = address(0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af);

    bytes32 public constant sushiDex = bytes32(0xcb2d20206d906069351c89a2cb7cdbd96c71998717cd5a82e724d955b654f67a);
    bytes32 public constant balancerDex = bytes32(0x9e73ce1e99df7d45bc513893badf42bc38069f1564ee511b0c8988f72f127b13);
    bytes32 public constant quickDex = bytes32(0x7bfa33731cff39bf8528ed70e5709ec0b799f5230ae0e1856a15d99aa053da30);
    bytes32 public constant mstableDex = bytes32(0x57a5a8ea4df7587ebb4c9aaa2bb3c9f9d459b4962f8b74c320c85916983e67db);

    address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address public constant balancerRouter = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
    bytes32 internal constant _SAVINGS_CONTRACT = 0x0500701c69c8b4e491f4e02f33040eaeadaae0eb72a88de7ae51e35a0e286a66;

    // this would be reset on each upgrade
    mapping (address => mapping (address => bytes32)) public storedLiquidationDexes;
    mapping (address => mapping (address => bytes32)) public storedBalancerPoolIds;
    address[] public rewardTokens;

    constructor() public BaseUpgradeableStrategy() {
        assert(_SAVINGS_CONTRACT == bytes32(uint256(keccak256("eip1967.strategyStorage.savingsContract")) - 1));
    }

    function _initializeStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address _rewardToken
    ) public initializer {
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            _rewardPool,
            _rewardToken,
            80, // profit sharing numerator
            1000, // profit sharing denominator
            true, // sell
            1e18, // sell floor
            12 hours // implementation change delay
        );

        rewardTokens = new address[](0);
    }

    function depositArbCheck() public pure returns(bool) {
        return true;
    }


    // If the return value is MAX_UINT256, it means that
    // the specified reward token is not in the list
    function getRewardTokenIndex(address rt) public view returns(uint256) {
      for(uint i = 0 ; i < rewardTokens.length ; i++){
        if(rewardTokens[i] == rt)
          return i;
      }
      return uint256(-1);
    }

    function addRewardToken(address rt) public onlyGovernance {
      require(getRewardTokenIndex(rt) == uint256(-1), "Reward token already exists");
      rewardTokens.push(rt);
    }

    function removeRewardToken(address rt) public onlyGovernance {
      uint256 i = getRewardTokenIndex(rt);
      require(i != uint256(-1), "Reward token does not exists");
      require(rewardTokens.length > 1, "Cannot remove the last reward token");
      uint256 lastIndex = rewardTokens.length - 1;

      // swap
      rewardTokens[i] = rewardTokens[lastIndex];

      // delete last element
      rewardTokens.pop();
    }

    function rewardPoolBalance() internal view returns (uint256 bal) {
        bal = IStakingRewardsWithPlatformToken(rewardPool()).balanceOf(address(this));
    }

    function exitRewardPool() internal {
        uint256 bal = rewardPoolBalance();
        if (bal == 0) {
            return;
        }

        uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
        // exit unstakes and claims any outstanding rewards (v-imUSD -> imUSD)
        IStakingRewardsWithPlatformToken(rewardPool()).exit();

        // withdraw from savings contract (imUSD -> mUSD)
        uint256 entireImUSDBalance = IERC20(imUSD).balanceOf(address(this));
        ISavingsContract(savingsContract()).redeemCredits(entireImUSDBalance);
    }

    function emergencyExitRewardPool() internal {
        uint256 bal = rewardPoolBalance();
        if (bal != 0) {
            // unstake without claiming rewards
            IStakingRewardsWithPlatformToken(rewardPool()).withdraw(bal);
        }

        // withdraw from savings contract (imUSD -> mUSD)
        uint256 entireImUSDBalance = IERC20(imUSD).balanceOf(address(this));
        if (entireImUSDBalance != 0) {
            ISavingsContract(savingsContract()).redeemCredits(entireImUSDBalance);
        }
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function enterRewardPool() internal {
        // deposit mUSD into savings contract to get imUSD
        uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

        IERC20(underlying()).safeApprove(savingsContract(), 0);
        IERC20(underlying()).safeApprove(savingsContract(), entireBalance);
        ISavingsContract(savingsContract()).depositSavings(entireBalance);

        // stake imUSD into reward pool to get v-imUSD
        uint256 entireImUSDBalance = IERC20(imUSD).balanceOf(address(this));
        IERC20(imUSD).safeApprove(rewardPool(), 0);
        IERC20(imUSD).safeApprove(rewardPool(), entireImUSDBalance);
        IStakingRewardsWithPlatformToken(rewardPool()).stake(entireImUSDBalance);
    }

    /*
    *   In case there are some issues discovered about the pool or underlying asset
    *   Governance can exit the pool properly
    *   The function is only used for emergency to exit the pool
    */
    function emergencyExit() public onlyGovernance {
        emergencyExitRewardPool();
        _setPausedInvesting(true);
    }

    /*
    *   Resumes the ability to invest into the underlying reward pools
    */

    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function shouldSell() internal returns(bool) {
        if(!sell()) {
            return false;
        }

        // get total balance in all reward tokens. not perfect, but it's something
        uint256 totalBalance = 0;
        for(uint256 i = 0; i < rewardTokens.length; i++){
            address token = rewardTokens[i];
            uint256 rewardBalance = IERC20(token).balanceOf(address(this));
            totalBalance = totalBalance.add(rewardBalance);
        }

        if (totalBalance < sellFloor()) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(sell(), totalBalance < sellFloor());
            return false;
        }
        
        return true;
    }


    function swapViaBalancer(address from, address to, uint256 amount) internal {
        //swap bal to weth on balancer
        IBVault.SingleSwap memory singleSwap;
        IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

        singleSwap.poolId = storedBalancerPoolIds[from][to];
        singleSwap.kind = swapKind;
        singleSwap.assetIn = IAsset(from);
        singleSwap.assetOut = IAsset(to);
        singleSwap.amount = amount;
        singleSwap.userData = abi.encode(0);

        IBVault.FundManagement memory funds;
        funds.sender = address(this);
        funds.fromInternalBalance = false;
        funds.recipient = payable(address(this));
        funds.toInternalBalance = false;

        IERC20(from).safeApprove(balancerRouter, 0);
        IERC20(from).safeApprove(balancerRouter, amount);

        IBVault(balancerRouter).swap(singleSwap, funds, 1, block.timestamp);
    }

    function swapViaMStable(address from, address to, uint256 amount) internal {
        IERC20(from).safeApprove(musd, 0);
        IERC20(from).safeApprove(musd, amount);
        if(to == musd) {
            // we can mint
            IMasset(musd).mint(
                from, // input token
                amount, // input quantity
                1, // min output quantity (we can accept 1 as the minimum because this will be called only by a trusted worker)
                address(this) // recipient
            );
        } else {
            // other swaps currently not needed and not implemented!
            return;
        }
    }

    function swapViaIUniswap(address from, address to, uint256 amount, address routerAddress) internal {
        IERC20(from).safeApprove(routerAddress, 0);
        IERC20(from).safeApprove(routerAddress, amount);

        address[] memory liquidationPath = new address[](2);
        liquidationPath[0] = from;
        liquidationPath[1] = to;

        IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
            amount,
             // we can accept 1 as the minimum because this will be called only by a trusted worker
            1,
            liquidationPath,
            address(this),
            block.timestamp
        );
    }

    function swapViaDex(address from, address to, uint256 amount) internal {
        if(storedLiquidationDexes[from][to] == quickDex) {
            swapViaIUniswap(from, to, amount, quickswapRouterV2);
        } else if(storedLiquidationDexes[from][to] == sushiDex) {
            swapViaIUniswap(from, to, amount, sushiswapRouterV2);
        } else if(storedLiquidationDexes[from][to] == balancerDex) {
            swapViaBalancer(from, to, amount);
        } else if(storedLiquidationDexes[from][to] == mstableDex) {
            swapViaMStable(from, to, amount);
        } else {
            // no dex defined, this should not happen since it is also checked before
            return;
        }
    }

    function strategyRewardsToRewardToken() internal {
        // swap rewards to WETH (rewardToken)
        for(uint256 i = 0; i < rewardTokens.length; i++){
            address token = rewardTokens[i];
            uint256 rewardBalance = IERC20(token).balanceOf(address(this));
            if (rewardBalance == 0 || storedLiquidationDexes[token][rewardToken()].length < 1) {
                continue;
            }

            swapViaDex(token, rewardToken(), rewardBalance);
        }
    }

    function rewardTokenToUnderlying() internal  {
        // must first swap rewardToken to tradeable asset on mStable, such as DAI
        uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));

        if (rewardBalance == 0 || storedLiquidationDexes[rewardToken()][dai].length < 1) {
            return;
        }
        swapViaDex(rewardToken(), dai, rewardBalance);

        // swap DAI to underlying on mStable
        uint256 daiBalance = IERC20(dai).balanceOf(address(this));
        if (daiBalance == 0 || storedLiquidationDexes[dai][underlying()].length < 1) {
            return;
        }
        swapViaDex(dai, underlying(), daiBalance);
    }

    function liquidateReward() internal {
        if (!shouldSell()) {
            return;
        }

        // MTA and WMATIC to WETH
        strategyRewardsToRewardToken();

        uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
        notifyProfitInRewardToken(rewardBalance);
        uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

        if (remainingRewardBalance == 0) {
            return;
        }

        // WETH to underlying (WETH -> DAI -> mUSD)
        rewardTokenToUnderlying();
    }

    /*
    *   Stakes everything the strategy holds into the reward pool
    */
    function investAllUnderlying() internal onlyNotPausedInvesting {
        // ensure there is any balance to invest
        if(IERC20(underlying()).balanceOf(address(this)) > 0) {
            enterRewardPool();
        }
    }

    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawAllToVault() public restricted {
        if (address(rewardPool()) != address(0)) {
            // this also claims all oustanding rewards
            exitRewardPool();
        }
        liquidateReward();
        IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
    }

    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawToVault(uint256 amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

        if(amount > entireBalance){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);

            // Note that we need to withdraw a certain amount in mUSD while invested is in imUSD (Credits with exchange rate)
            // so we need to calculate accordingly (toWithraw must be the amount in credits that equals input amount in mUSD)
            uint256 amountToWithdrawInCredits = ISavingsContract(savingsContract()).underlyingToCredits(needToWithdraw);
            uint256 toWithdraw = Math.min(rewardPoolBalance(), amountToWithdrawInCredits);

            // unstake (v-imUSD -> imUSD)
            IStakingRewardsWithPlatformToken(rewardPool()).withdraw(toWithdraw);

            // withdraw from savings contract (imUSD -> mUSD)
            ISavingsContract(savingsContract()).redeemCredits(toWithdraw);
        }

        IERC20(underlying()).safeTransfer(vault(), amount);
    }

    /*
    *   Note that we currently do not have a mechanism here to include the
    *   amount of reward that is accrued.
    */
    function investedUnderlyingBalance() external view returns (uint256) {
        uint256 underlyingBalance = IERC20(underlying()).balanceOf(address(this));
        if (rewardPool() == address(0)) {
            return underlyingBalance;
        }


        uint256 rewardPoolBalanceImUSD = rewardPoolBalance();

        // reward pool balance is in imUSD which actual value in mUSD depends on an exchange rate set in the savings contract
        uint256 rewardPoolBalanceInUnderlying = ISavingsContract(savingsContract()).creditsToUnderlying(rewardPoolBalanceImUSD);

        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return rewardPoolBalanceInUnderlying.add(underlyingBalance);
    }

    /*
    *   Governance or Controller can claim coins that are somehow transferred into the contract
    *   Note that they cannot come in take away coins that are used and defined in the strategy itself
    */
    function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }

    /*
    *   Get the reward, sell it in exchange for underlying, invest what you got.
    *   It's not much, but it's honest work.
    */
    function doHardWork() external onlyNotPausedInvesting restricted {
        // claims both the platformToken and the rewardsToken (MTA & WMATIC)
        IStakingRewardsWithPlatformToken(rewardPool()).claimReward();
        liquidateReward();
        investAllUnderlying();
    }

    /**
    * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
    * simplest possible way.
    */
    function setSell(bool s) public onlyGovernance {
        _setSell(s);
    }

    /**
    * Sets the minimum amount of earnings in any reward token needed to trigger a sale.
    */
    function setSellFloor(uint256 floor) public onlyGovernance {
        _setSellFloor(floor);
    }


    function setBalancerPoolId(address from, address to, bytes32 poolId) public onlyGovernance {
        storedBalancerPoolIds[from][to] = poolId;
    }

    function setLiquidationDex(address from, address to, bytes32 dex) public onlyGovernance {
        storedLiquidationDexes[from][to] = dex;
    }

    function setSavingsContract(address savingsContract)  public onlyGovernance {
        require(address(ISavingsContract(savingsContract).underlying()) == underlying(), 'underlying does not match savings contract underlying');
        return setAddress(_SAVINGS_CONTRACT, savingsContract);
    }

    function savingsContract() public view returns (address) {
        return getAddress(_SAVINGS_CONTRACT);
    }

    function finalizeUpgrade() external virtual onlyGovernance {
        _finalizeUpgrade();
    }
}

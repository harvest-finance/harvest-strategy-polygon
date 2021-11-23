//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "./interface/IElysianFields.sol";
import "../../base/PotPool.sol";
import "../../base/interface/kyber/IDMMRouter02.sol";
import "../../base/interface/kyber/IDMMPool.sol";

contract JarvisHodlStrategyV2 is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant kyberRouter = address(0x546C79662E028B661dFB4767664d0273184E4dD1);
  address public constant msig = address(0x39cC360806b385C96969ce9ff26c23476017F652);
  uint256 internal constant maxUint = uint256(~0);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _HODLVAULT_SLOT = 0xc26d330f887c749cb38ae7c37873ff08ac4bba7aec9113c82d48a0cf6cc145f2;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;
  bytes32 internal constant _REWARD_LP_SLOT = 0x48141e8830aff32be47daedfc211bdc62d1652246e1c94ca6dfd96128ee259d2;
  bytes32 internal constant _REWARD_LP_TOKEN1_SLOT = 0x39bbed0fce4dadfae510b0ff92e23dc8458ac86daafb72558e64503559b640ed;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_HODLVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.hodlVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
    assert(_REWARD_LP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardLp")) - 1));
    assert(_REWARD_LP_TOKEN1_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardLpToken1")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _poolId,
    address _rewardLp,
    address _hodlVault,
    address _potPool
  ) public initializer {
    require(_rewardPool != address(0), "reward pool is empty");

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e15, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IElysianFields(rewardPool()).poolInfo(_poolId);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolId);
    setAddress(_REWARD_LP_SLOT, _rewardLp);
    setAddress(_HODLVAULT_SLOT, _hodlVault);
    setAddress(_POTPOOL_SLOT, _potPool);
    address rewardLpToken1 = (IDMMPool(rewardLp()).token0() == rewardToken()) ? IDMMPool(rewardLp()).token1() : IDMMPool(rewardLp()).token0();
    setAddress(_REWARD_LP_TOKEN1_SLOT, rewardLpToken1);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IElysianFields(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IElysianFields(rewardPool()).withdraw(poolId(), bal);
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IElysianFields(rewardPool()).emergencyWithdraw(poolId());
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IElysianFields(rewardPool()).deposit(poolId(), entireBalance);
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

  // We Hodl all the rewards
  function _hodlAndNotify() internal {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    if (rewardBalance == 0) {
      return;
    }
    uint256 feeAmount = rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
    IERC20(rewardToken()).safeTransfer(msig, feeAmount);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    rewardToLp();
    uint256 rewardLpBalance = IERC20(rewardLp()).balanceOf(address(this));
    IERC20(rewardLp()).safeApprove(hodlVault(), 0);
    IERC20(rewardLp()).safeApprove(hodlVault(), rewardLpBalance);
    IVault(hodlVault()).deposit(rewardLpBalance);
    uint256 fRewardBalance = IERC20(hodlVault()).balanceOf(address(this));
    IERC20(hodlVault()).safeTransfer(potPool(), fRewardBalance);
    PotPool(potPool()).notifyTargetRewardAmount(hodlVault(), fRewardBalance);
  }

  function rewardToLp() internal {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    uint256 toSwap = rewardBalance.div(2);
    uint256 remainingReward = rewardBalance.sub(toSwap);
    address[] memory poolsPath = new address[](1);
    poolsPath[0] = rewardLp();
    address[] memory path = new address[](2);
    path[0] = rewardToken();
    path[1] = rewardLpToken1();
    uint256 balanceBefore = IERC20(underlying()).balanceOf(address(this));

    IERC20(rewardToken()).safeApprove(kyberRouter, 0);
    IERC20(rewardToken()).safeApprove(kyberRouter, rewardBalance);
    IDMMRouter02(kyberRouter).swapExactTokensForTokens(
        toSwap,
        1,
        poolsPath,
        path,
        address(this),
        block.timestamp
    );

    uint256 rewardLpToken1Balance;
    if (rewardLpToken1() == underlying()) {
      uint256 balanceAfter = IERC20(underlying()).balanceOf(address(this));
      rewardLpToken1Balance = balanceAfter.sub(balanceBefore);
    } else {
      rewardLpToken1Balance = IERC20(rewardLpToken1()).balanceOf(address(this));
    }
    uint256[2] memory vReserveRatioBounds = [1, maxUint];
    IERC20(rewardLpToken1()).safeApprove(kyberRouter, 0);
    IERC20(rewardLpToken1()).safeApprove(kyberRouter, rewardLpToken1Balance);
    IDMMRouter02(kyberRouter).addLiquidity(
        rewardToken(),
        rewardLpToken1(),
        rewardLp(),
        remainingReward,
        rewardLpToken1Balance,
        1,
        1,
        vReserveRatioBounds,
        address(this),
        block.timestamp
    );
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    exitRewardPool();
    _hodlAndNotify();
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
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IElysianFields(rewardPool()).withdraw(poolId(), toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
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
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IElysianFields(rewardPool()).withdraw(poolId(), 0);
    _hodlAndNotify();
    investAllUnderlying();
  }

  function setHodlVault(address _value) public onlyGovernance {
    require(hodlVault() == address(0), "Hodl vault already set");
    setAddress(_HODLVAULT_SLOT, _value);
  }

  function hodlVault() public view returns (address) {
    return getAddress(_HODLVAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function setRewardLp(address _value) public onlyGovernance {
    setAddress(_REWARD_LP_SLOT, _value);
  }

  function rewardLp() public view returns (address) {
    return getAddress(_REWARD_LP_SLOT);
  }

  function setRewardLpToken1(address _value) public onlyGovernance {
    setAddress(_REWARD_LP_TOKEN1_SLOT, _value);
  }

  function rewardLpToken1() public view returns (address) {
    return getAddress(_REWARD_LP_TOKEN1_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "./interfaces/ILiquidityMining.sol";
import "./interfaces/IProxyActions.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IUSDCVault.sol";
import "./interfaces/IPermanentLiquidityPool.sol";
import "./interfaces/IDesignatedPoolRegistry.sol";

import "hardhat/console.sol";

contract ComplifiStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _BASE_TOKEN_SLOT = 0xb9ace61e05bb293514c5e5999b24c7962eaa62eb455b54d96399829431bfd425;
  bytes32 internal constant _PROXY_SLOT = 0xe0898eac8b9a936189ab0c51fb8795de984bdabad6d1a277d006fecbf46049ee;
  bytes32 internal constant _MULTISIG_SLOT = 0x3e9de78b54c338efbc04e3a091b87dc7efb5d7024738302c548fc59fba1c34e6;

  // this would be reset on each upgrade
  address[] public liquidationPath;

  modifier onlyMultiSigOrGovernance() {
    require(msg.sender == multiSig() || msg.sender == governance(), "The sender has to be multiSig or governance");
    _;
  }

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_BASE_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.baseToken")) - 1));
    assert(_PROXY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.proxy")) - 1));
    assert(_MULTISIG_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.multiSig")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    address _baseToken,
    address _proxy
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

    address _lpt;
    uint256 pid = ILiquidityMining(rewardPool()).poolPidByAddress(_underlying);
    (_lpt,,,) = ILiquidityMining(rewardPool()).poolInfo(pid);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(pid);
    _setBaseToken(_baseToken);
    _setProxy(_proxy);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 balUnderlying) {
      (balUnderlying,) = ILiquidityMining(rewardPool()).userPoolInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 balUnderlying = rewardPoolBalance();
      if (balUnderlying != 0) {
          ILiquidityMining(rewardPool()).withdraw(poolId(), balUnderlying);
      }
  }

  function emergencyExitRewardPool() internal {
    uint256 balUnderlying = rewardPoolBalance();
      if (balUnderlying != 0) {
          ILiquidityMining(rewardPool()).withdrawEmergency(poolId());
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    ILiquidityMining(rewardPool()).deposit(poolId(), entireBalance);
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

  function setLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[0] == rewardToken(), "Path should start with reward");
    require(_route[_route.length-1] == baseToken(), "Path should end with baseToken");
    liquidationPath = _route;
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward() internal {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    console.log("Reward balance:", rewardBalance);
    if (!sell() || rewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    console.log("Remaining reward balance:", remainingRewardBalance);
    if (remainingRewardBalance == 0) {
      return;
    }

    // allow Uniswap to sell our reward
    IERC20(rewardToken()).safeApprove(quickswapRouterV2, 0);
    IERC20(rewardToken()).safeApprove(quickswapRouterV2, remainingRewardBalance);

    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    IUniswapV2Router02(quickswapRouterV2).swapExactTokensForTokens(
      remainingRewardBalance,
      amountOutMin,
      liquidationPath,
      address(this),
      block.timestamp
    );
    uint256 baseBalance = IERC20(baseToken()).balanceOf(address(this));
    if (baseBalance > 0){
      _baseToUnderlying();
    }
  }

  function _baseToUnderlying() internal {
    uint256 baseBalance = IERC20(baseToken()).balanceOf(address(this));
    console.log("Base balance:", baseBalance);
    IERC20(baseToken()).safeApprove(proxy(), 0);
    IERC20(baseToken()).safeApprove(proxy(), baseBalance);
    address pool = IPermanentLiquidityPool(underlying()).designatedPool();
    uint256[] memory filler = new uint256[](0);

    IProxyActions(proxy()).mintAndJoinPoolPermanent(underlying(), filler, pool, baseBalance, address(0), 0, address(0), 0, 0);
    IProxyActions(proxy()).extractChange(pool);
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
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    ILiquidityMining(rewardPool()).claim();
    _liquidateReward();
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
      ILiquidityMining(rewardPool()).withdraw(poolId(), toWithdraw);
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
    ILiquidityMining(rewardPool()).claim();
    _liquidateReward();
    investAllUnderlying();
  }

  function claimRewards() external onlyMultiSigOrGovernance {
    ILiquidityMining(rewardPool()).claim();
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    IERC20(rewardToken()).safeTransfer(msg.sender, remainingRewardBalance);
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function _setBaseToken(address _address) internal {
    setAddress(_BASE_TOKEN_SLOT, _address);
  }

  function baseToken() public view returns (address) {
    return getAddress(_BASE_TOKEN_SLOT);
  }

  function _setProxy(address _address) internal {
    setAddress(_PROXY_SLOT, _address);
  }

  function proxy() public view returns (address) {
    return getAddress(_PROXY_SLOT);
  }

  function setMultiSig(address _address) public onlyGovernance {
    setAddress(_MULTISIG_SLOT, _address);
  }

  function multiSig() public view returns (address) {
    return getAddress(_MULTISIG_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

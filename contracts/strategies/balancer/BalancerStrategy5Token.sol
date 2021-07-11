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
import "./interface/IBVault.sol";

contract BalancerStrategy5Token is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public constant bal = address(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _BVAULT_SLOT = 0x85cbd475ba105ca98d9a2db62dcf7cf3c0074b36303ef64160d68a3e0fdd3c67;
  bytes32 internal constant _LIQUIDATION_RATIO_SLOT = 0x88a908c31cfd33a7a64870721e6da89f529116031d2cb9ed0bf1c4ba0873d19f;
  bytes32 internal constant _USE_QUICK_SLOT = 0x189f8e6d384b6a451390d61330a1995a733994439125cd881a1bdac25fe65ea2;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _BAL2WETH_POOLID_SLOT = 0x45ba019d7bbdedd3bc4822691e4d804339c1a4b73290d1f7370a432fe65381d4;
  bytes32 internal constant _DEPOSIT_ARRAY_INDEX_SLOT = 0xf5304231d5b8db321cd2f83be554278488120895d3326b9a012d540d75622ba3;

  // this would be reset on each upgrade
  address[] public WETH2deposit;
  address[] public poolAssets;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_BVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bVault")) - 1));
    assert(_LIQUIDATION_RATIO_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.liquidationRatio")) - 1));
    assert(_USE_QUICK_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.useQuick")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_BAL2WETH_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bal2WethPoolId")) - 1));
    assert(_DEPOSIT_ARRAY_INDEX_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositArrayIndex")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _bVault,
    bytes32 _poolID,
    uint256 _liquidationRatio,
    address _depositToken,
    uint256 _depositArrayIndex,
    bool _useQuick,
    bytes32 _bal2wethpid
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      address(this),
      weth,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    (address _lpt,) = IBVault(_bVault).getPool(_poolID);
    require(_lpt == _underlying, "Underlying mismatch");
    require(_liquidationRatio < 1000, "Invalid ratio"); //Ratio base = 1000

    setLiquidationRatio(_liquidationRatio);
    _setPoolId(_poolID);
    _setBal2WethPoolId(_bal2wethpid);
    _setBVault(_bVault);
    _setDepositToken(_depositToken);
    _setDepositArrayIndex(_depositArrayIndex);
    setUseQuick(_useQuick);
    WETH2deposit = new address[](0);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function underlyingBalance() internal view returns (uint256 balance) {
      balance = IERC20(underlying()).balanceOf(address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[0] == rewardToken(), "Path should start with rewardToken");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
  }

  function changeDepositToken(address _depositToken, address[] memory _liquidationPath, uint256 _depositArrayIndex) public onlyGovernance {
    _setDepositToken(_depositToken);
    setLiquidationPath(_liquidationPath);
    _setDepositArrayIndex(_depositArrayIndex);
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateReward(uint256 balAmount) internal {
    if (!sell() || balAmount < sellFloor() || balAmount == 0) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), balAmount < sellFloor());
      return;
    }
    //swap bal to weth on balancer
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = bal2WethPoolId();
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(bal);
    singleSwap.assetOut = IAsset(weth);
    singleSwap.amount = balAmount;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    IERC20(bal).safeApprove(bVault(), 0);
    IERC20(bal).safeApprove(bVault(), balAmount);

    IBVault(bVault()).swap(singleSwap, funds, 1, block.timestamp);

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if (WETH2deposit.length > 1) { //else we assume WETH is the deposit token, no need to swap
      address routerV2;
      if(useQuick()) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      // allow Uniswap to sell our reward
      IERC20(rewardToken()).safeApprove(routerV2, 0);
      IERC20(rewardToken()).safeApprove(routerV2, remainingRewardBalance);

      // we can accept 1 as minimum because this is called only by a trusted role
      uint256 amountOutMin = 1;

      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        remainingRewardBalance,
        amountOutMin,
        WETH2deposit,
        address(this),
        block.timestamp
      );
    }

    uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
    if (tokenBalance > 0) {
      depositLP();
    }
  }

  function depositLP() internal {
    uint256 depositTokenBalance = IERC20(depositToken()).balanceOf(address(this));

    IERC20(depositToken()).safeApprove(bVault(), 0);
    IERC20(depositToken()).safeApprove(bVault(), depositTokenBalance);

    IAsset[] memory assets = new IAsset[](5);
    assets[0] = IAsset(poolAssets[0]);
    assets[1] = IAsset(poolAssets[1]);
    assets[2] = IAsset(poolAssets[2]);
    assets[3] = IAsset(poolAssets[3]);
    assets[4] = IAsset(poolAssets[4]);

    IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
    uint256[] memory amountsIn = new uint256[](5);
    amountsIn[depositArrayIndex()] = depositTokenBalance;
    uint256 minAmountOut = 1;

    bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

    IBVault.JoinPoolRequest memory request;
    request.assets = assets;
    request.maxAmountsIn = amountsIn;
    request.userData = userData;
    request.fromInternalBalance = false;

    IBVault(bVault()).joinPool(
      poolId(),
      address(this),
      address(this),
      request
    );
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    _liquidateReward(rewardBalance);
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if (amount >= entireBalance){
      withdrawAllToVault();
    } else {
      IERC20(underlying()).safeTransfer(vault(), amount);
    }
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return underlyingBalance();
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
    uint256 balBalance = IERC20(bal).balanceOf(address(this));
    _liquidateReward(balBalance.mul(liquidationRatio()).div(1000));
  }

  function liquidateAll() external onlyGovernance {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    _liquidateReward(rewardBalance);
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
  function _setPoolId(bytes32 _value) internal {
    setBytes32(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (bytes32) {
    return getBytes32(_POOLID_SLOT);
  }

  function _setBVault(address _address) internal {
    setAddress(_BVAULT_SLOT, _address);
  }

  function bVault() public view returns (address) {
    return getAddress(_BVAULT_SLOT);
  }

  function setLiquidationRatio(uint256 _ratio) public onlyGovernance {
    require(_ratio < 1000, "Invalid ratio"); //Ratio base = 1000
    setUint256(_LIQUIDATION_RATIO_SLOT, _ratio);
  }

  function liquidationRatio() public view returns (uint256) {
    return getUint256(_LIQUIDATION_RATIO_SLOT);
  }

  function setUseQuick(bool _value) public onlyGovernance {
    setBoolean(_USE_QUICK_SLOT, _value);
  }

  function useQuick() public view returns (bool) {
    return getBoolean(_USE_QUICK_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function _setBal2WethPoolId(bytes32 _value) internal {
    setBytes32(_BAL2WETH_POOLID_SLOT, _value);
  }

  function bal2WethPoolId() public view returns (bytes32) {
    return getBytes32(_BAL2WETH_POOLID_SLOT);
  }

  function _setDepositArrayIndex(uint256 _value) internal {
    setUint256(_DEPOSIT_ARRAY_INDEX_SLOT, _value);
  }

  function depositArrayIndex() public view returns (uint256) {
    return getUint256(_DEPOSIT_ARRAY_INDEX_SLOT);
  }

  function setBytes32(bytes32 slot, bytes32 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getBytes32(bytes32 slot) internal view returns (bytes32 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

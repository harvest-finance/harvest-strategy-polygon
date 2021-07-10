//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/curve/ICurveDeposit_2token_underlying.sol";
import "../../base/interface/curve/Gauge.sol";

contract CurveStrategyRen is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant quickswapRouterV2 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
  address public constant sushiswapRouterV2 = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _USE_QUICK_SLOT = 0x189f8e6d384b6a451390d61330a1995a733994439125cd881a1bdac25fe65ea2;
  bytes32 internal constant _DEPOSIT_ARRAY_POSITION_SLOT = 0xb7c50ef998211fff3420379d0bf5b8dfb0cee909d1b7d9e517f311c104675b09;
  bytes32 internal constant _CURVE_DEPOSIT_SLOT = 0xb306bb7adebd5a22f5e4cdf1efa00bc5f62d4f5554ef9d62c1b16327cd3ab5f9;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;

  address[] public WETH2deposit;
  mapping (address => address[]) public reward2WETH;
  mapping (address => bool) public useQuick;
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_USE_QUICK_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.useQuick")) - 1));
    assert(_DEPOSIT_ARRAY_POSITION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositArrayPosition")) - 1));
    assert(_CURVE_DEPOSIT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.curveDeposit")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _depositArrayPosition,
    address _curveDeposit,
    address _depositToken
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      80, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      0, // sell floor
      12 hours // implementation change delay
    );
    require(_depositArrayPosition < 2, "Deposit array position out of bounds");
    _setDepositArrayPosition(_depositArrayPosition);
    _setCurveDeposit(_curveDeposit);
    _setDepositToken(_depositToken);
    WETH2deposit = new address[](0);
    rewardTokens = new address[](0);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      bal = Gauge(rewardPool()).balanceOf(address(this));
  }

  function withdrawUnderlyingFromPool(uint256 amount) internal {
    Gauge(rewardPool()).withdraw(
      Math.min(Gauge(rewardPool()).balanceOf(address(this)), amount)
    );
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
        withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    Gauge(rewardPool()).deposit(entireBalance);
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

  function setDepositLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
    useQuick[_route[_route.length-1]] = _useQuick;
  }

  function setRewardLiquidationPath(address [] memory _route, bool _useQuick) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
    useQuick[_route[0]] = _useQuick;
  }

  function addRewardToken(address _token, address[] memory _path2WETH, bool _useQuick) public onlyGovernance {
    require(_path2WETH[_path2WETH.length-1] == weth, "Path should end with WETH");
    require(_path2WETH[0] == _token, "Path should start with rewardToken");
    rewardTokens.push(_token);
    reward2WETH[_token] = _path2WETH;
    useQuick[_token] = _useQuick;
  }

  function changeDepositToken(address _depositToken, address[] memory _WETH2token, bool _useQuick, uint256 _depositArrayPosition) public onlyGovernance {
    _setDepositArrayPosition(_depositArrayPosition);
    _setDepositToken(_depositToken);
    setDepositLiquidationPath(_WETH2token, _useQuick);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapoolId exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));
      if (rewardBalance == 0 || reward2WETH[token].length < 2) {
        continue;
      }

      address routerV2;
      if(useQuick[token]) {
        routerV2 = quickswapRouterV2;
      } else {
        routerV2 = sushiswapRouterV2;
      }
      IERC20(token).safeApprove(routerV2, 0);
      IERC20(token).safeApprove(routerV2, rewardBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(routerV2).swapExactTokensForTokens(
        rewardBalance, 1, reward2WETH[token], address(this), block.timestamp
      );
    }

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address routerV2;
    if(useQuick[depositToken()]) {
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

    uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
    if (tokenBalance > 0) {
      depositCurve();
    }
  }

  function depositCurve() internal {
    uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
    IERC20(depositToken()).safeApprove(curveDeposit(), 0);
    IERC20(depositToken()).safeApprove(curveDeposit(), tokenBalance);

    uint256[2] memory depositArray;
    depositArray[depositArrayPosition()] = tokenBalance;

    // we can accept 0 as minimum, this will be called only by trusted roles
    uint256 minimum = 0;
    ICurveDeposit_2token_underlying(curveDeposit()).add_liquidity(depositArray, minimum, true);
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
    withdrawUnderlyingFromPool(rewardPoolBalance());
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
      withdrawUnderlyingFromPool(toWithdraw);
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
    Gauge(rewardPool()).claim_rewards();
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  function _setDepositArrayPosition(uint256 _value) internal {
    setUint256(_DEPOSIT_ARRAY_POSITION_SLOT, _value);
  }

  function depositArrayPosition() public view returns (uint256) {
    return getUint256(_DEPOSIT_ARRAY_POSITION_SLOT);
  }

  function _setCurveDeposit(address _address) internal {
    setAddress(_CURVE_DEPOSIT_SLOT, _address);
  }

  function curveDeposit() public view returns (address) {
    return getAddress(_CURVE_DEPOSIT_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

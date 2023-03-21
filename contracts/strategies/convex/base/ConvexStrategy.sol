//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../interface/IBooster.sol";
import "../interface/IBaseRewardPool.sol";
import "../../../base/interface/uniswap/IUniswapV3Router.sol";
import "../../../base/interface/curve/ICurveDeposit_2token.sol";
import "../../../base/interface/curve/ICurveDeposit_3token_underlying.sol";
import "../../../base/interface/curve/ICurveDeposit_3token_meta.sol";
import "../../../base/interface/curve/ICurveDeposit_4token.sol";
import "../../../base/interface/curve/ICurveDeposit_4token_meta.sol";
import "../../../base/interface/curve/ICurveDeposit_5token.sol";
import "../../../base/interface/curve/ICurveDeposit_5token_meta.sol";
import "../../../base/interface/curve/ICurveDeposit_6token.sol";
import "../../../base/interface/curve/ICurveDeposit_6token_meta.sol";
import "../../../base/interface/curve/Gauge.sol";

contract ConvexStrategy is BaseUpgradeableStrategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
  address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public constant uniV3Router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _DEPOSIT_ARRAY_POSITION_SLOT = 0xb7c50ef998211fff3420379d0bf5b8dfb0cee909d1b7d9e517f311c104675b09;
  bytes32 internal constant _CURVE_DEPOSIT_SLOT = 0xb306bb7adebd5a22f5e4cdf1efa00bc5f62d4f5554ef9d62c1b16327cd3ab5f9;
  bytes32 internal constant _NTOKENS_SLOT = 0xbb60b35bae256d3c1378ff05e8d7bee588cd800739c720a107471dfa218f74c1;
  bytes32 internal constant _METAPOOL_SLOT = 0x567ad8b67c826974a167f1a361acbef5639a3e7e02e99edbc648a84b0923d5b7;

  // this would be reset on each upgrade
  address[] public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  address[] public rewardTokens;
  mapping (address => mapping(address => uint24)) public storedPairFee;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_DEPOSIT_ARRAY_POSITION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositArrayPosition")) - 1));
    assert(_CURVE_DEPOSIT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.curveDeposit")) - 1));
    assert(_NTOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nTokens")) - 1));
    assert(_METAPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.metaPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _poolID,
    address _depositToken,
    uint256 _depositArrayPosition,
    address _curveDeposit,
    uint256 _nTokens,
    bool _metaPool
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

    address _lpt;
    (_lpt,,,,) = IBooster(booster).poolInfo(_poolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    require(_depositArrayPosition < _nTokens, "Deposit array position out of bounds");
    require(1 < _nTokens && _nTokens < 7, "_nTokens should be between 2 and 6");
    _setDepositArrayPosition(_depositArrayPosition);
    _setPoolId(_poolID);
    _setDepositToken(_depositToken);
    _setCurveDeposit(_curveDeposit);
    _setNTokens(_nTokens);
    _setMetaPool(_metaPool);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      bal = IBaseRewardPool(rewardPool()).balanceOf(address(this));
  }

  function exitRewardPool() internal {
      uint256 stakedBalance = rewardPoolBalance();
      if (stakedBalance != 0) {
          IBaseRewardPool(rewardPool()).withdrawAll(true);
      }
  }

  function partialWithdrawalRewardPool(uint256 amount) internal {
    IBaseRewardPool(rewardPool()).withdraw(amount, false);  //don't claim rewards at this point
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
        IBaseRewardPool(rewardPool()).withdrawAll(false); //don't claim rewards
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(booster, 0);
    IERC20(_underlying).safeApprove(booster, entireBalance);
    IBooster(booster).depositAll(poolId()); //deposit and stake
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

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
  }

  function addRewardToken(address _token, address[] memory _path2WETH) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WETH);
  }

  function changeDepositToken(address _depositToken, address[] memory _liquidationPath) public onlyGovernance {
    _setDepositToken(_depositToken);
    setDepositLiquidationPath(_liquidationPath);
  }

  function uniV3PairFee(address sellToken, address buyToken) public view returns(uint24 fee) {
    if(storedPairFee[sellToken][buyToken] != 0) {
      return storedPairFee[sellToken][buyToken];
    } else if(storedPairFee[buyToken][sellToken] != 0) {
      return storedPairFee[buyToken][sellToken];
    } else {
      return 3000;
    }
  }

  function setPairFee(address token0, address token1, uint24 fee) public onlyGovernance {
    storedPairFee[token0][token1] = fee;
  }

  function uniV3Swap(
    uint256 amountIn,
    uint256 minAmountOut,
    address[] memory pathWithoutFee
  ) internal {
    address currentSellToken = pathWithoutFee[0];

    IERC20(currentSellToken).safeIncreaseAllowance(uniV3Router, amountIn);

    bytes memory pathWithFee = abi.encodePacked(currentSellToken);
    for(uint256 i=1; i < pathWithoutFee.length; i++) {
      address currentBuyToken = pathWithoutFee[i];
      pathWithFee = abi.encodePacked(
        pathWithFee,
        uniV3PairFee(currentSellToken, currentBuyToken),
        currentBuyToken);
      currentSellToken = currentBuyToken;
    }

    IUniswapV3Router.ExactInputParams memory param = IUniswapV3Router.ExactInputParams({
      path: pathWithFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    IUniswapV3Router(uniV3Router).exactInput(param);
  }

  // We assume that all the tradings can be done on Sushiswap
  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapoolId exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    address _depositToken = depositToken();

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if(reward2WETH[token].length < 2 || rewardBalance < 1e15) {
        continue;
      }
      uniV3Swap(rewardBalance, 1, reward2WETH[token]);
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if(_depositToken != _rewardToken) {
      uniV3Swap(remainingRewardBalance, 1, WETH2deposit);
    }

    uint256 tokenBalance = IERC20(_depositToken).balanceOf(address(this));
    if (tokenBalance > 0) {
      depositCurve();
    }
  }

  function depositCurve() internal {
    address _depositToken = depositToken();
    address _curveDeposit = curveDeposit();
    uint256 _nTokens = nTokens();
    uint256 _depositArrayPosition = depositArrayPosition();
    bool _metaPool = metaPool();

    uint256 tokenBalance = IERC20(_depositToken).balanceOf(address(this));
    IERC20(_depositToken).safeApprove(_curveDeposit, 0);
    IERC20(_depositToken).safeApprove(_curveDeposit, tokenBalance);

    // we can accept 1 as minimum, this will be called only by trusted roles
    uint256 minimum = 1;
    if (_nTokens == 2) {
      uint256[2] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      ICurveDeposit_2token(_curveDeposit).add_liquidity(depositArray, minimum);
    } else if (_nTokens == 3) {
      uint256[3] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      if (_metaPool) {
        address pool = ICurveLP(underlying()).minter();
        ICurveDeposit_3token_meta(_curveDeposit).add_liquidity(pool, depositArray, minimum);
      } else {
        ICurveDeposit_3token_underlying(_curveDeposit).add_liquidity(depositArray, minimum, true);
      }
    } else if (_nTokens == 4) {
      uint256[4] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      if (_metaPool) {
        address pool = ICurveLP(underlying()).minter();
        ICurveDeposit_4token_meta(_curveDeposit).add_liquidity(pool, depositArray, minimum);
      } else {
        ICurveDeposit_4token(_curveDeposit).add_liquidity(depositArray, minimum);
      }
    } else if (_nTokens == 5) {
      uint256[5] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      if (_metaPool) {
        address pool = ICurveLP(underlying()).minter();
        ICurveDeposit_5token_meta(_curveDeposit).add_liquidity(pool, depositArray, minimum);
      } else {
        ICurveDeposit_5token(_curveDeposit).add_liquidity(depositArray, minimum);
      }
    } else if (_nTokens == 6) {
      uint256[6] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      if (_metaPool) {
        address pool = ICurveLP(underlying()).minter();
        ICurveDeposit_6token_meta(_curveDeposit).add_liquidity(pool, depositArray, minimum);
      } else {
        ICurveDeposit_6token(_curveDeposit).add_liquidity(depositArray, minimum);
      }
    }
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
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return rewardPoolBalance()
      .add(IERC20(underlying()).balanceOf(address(this)));
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
    IBaseRewardPool(rewardPool()).getReward(address(this));
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

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
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

  function _setNTokens(uint256 _value) internal {
    setUint256(_NTOKENS_SLOT, _value);
  }

  function nTokens() public view returns (uint256) {
    return getUint256(_NTOKENS_SLOT);
  }

  function _setMetaPool(bool _value) internal {
    setBoolean(_METAPOOL_SLOT, _value);
  }

  function metaPool() public view returns (bool) {
    return getBoolean(_METAPOOL_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}
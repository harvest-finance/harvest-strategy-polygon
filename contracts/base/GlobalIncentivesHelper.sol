// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./NotifyHelperStateful.sol";
import "./NotifyHelperGeneric.sol";
import "./inheritance/Controllable.sol";

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract GlobalIncentivesHelper is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public helperControlStorage;
  address public notifyHelperGeneric;
  address public escrow;
  address public reserve;
  address public farm;

  event ChangerSet(address indexed account, bool value);
  event NotifierSet(address indexed account, bool value);
  event Vesting(address pool, uint256 amount);
  event PoolChanged(address indexed pool, uint256 percentage, uint256 notificationType, bool vests);

  enum NotificationType {
    VOID, AMPLIFARM, FARM, TRANSFER, PROFIT_SHARE, TOKEN
  }

  mapping (address => address) public tokenToHelper;
  mapping (address => bool) public changer;
  mapping (address => bool) public notifier;

  modifier onlyChanger {
    require(changer[msg.sender] || msg.sender == governance(), "Only changer");
    _;
  }

  modifier onlyNotifier {
    require(notifier[msg.sender] || msg.sender == governance(), "Only notifier");
    _;
  }

  constructor(address _storage, address _farm, address _farmHelper, address _notifyHelperGeneric, address _escrow, address _reserve) public Controllable(_storage) {
    tokenToHelper[_farm] = _farmHelper;
    farm = _farm;
    notifyHelperGeneric = _notifyHelperGeneric;
    helperControlStorage = address(new Storage());
    escrow = _escrow;
    reserve = _reserve;
  }

  function notifyPools(address[] calldata tokens, uint256[] calldata totals, uint256 timestamp) external onlyNotifier {
    for (uint256 i = 0; i < tokens.length; i++) {
      // IERC20Upgradeable(tokens[i]).safeTransferFrom(msg.sender, address(this), totals[i]);
      IERC20Upgradeable(tokens[i]).approve(tokenToHelper[tokens[i]], totals[i]);
      NotifyHelperStateful(tokenToHelper[tokens[i]]).notifyPools(totals[i], timestamp);
    }
  }

  // uses generic helper
  function newToken(address token) external onlyChanger {
    newTokenWithHelper(token, notifyHelperGeneric);
  }

  // uses a specific notify helper
  function newTokenWithHelper(address token, address notifyHelper) public onlyChanger {
    require(tokenToHelper[token] == address(0), "Token already initialized");
    tokenToHelper[token] = address(new NotifyHelperStateful(
      helperControlStorage,
      notifyHelper, // the universal helper should be sufficient in all cases
      token,
      address(0), // no iFARM/ampliFARM notify helper is needed
      escrow,
      reserve
    ));
    if (notifyHelper == notifyHelperGeneric) {
      NotifyHelperGeneric(notifyHelper).setWhitelist(tokenToHelper[token], true);
    }
    NotifyHelperStateful(tokenToHelper[token]).setNotifier(address(this), true);
    NotifyHelperStateful(tokenToHelper[token]).setNotifier(governance(), true);
    NotifyHelperStateful(tokenToHelper[token]).setChanger(address(this), true);
    NotifyHelperStateful(tokenToHelper[token]).setChanger(governance(), true);
  }

  function resetToken(address token) public onlyChanger {
    tokenToHelper[token] = address(0);
  }

  /// Whitelisted entity makes changes to the notifications
  function setPoolBatch(
    address[] calldata tokens,
    address[] calldata poolAddress,
    uint256[] calldata poolPercentage,
    NotificationType[] calldata notificationType,
    bool[] calldata vests) external onlyChanger {
    for (uint256 i = 0; i < poolAddress.length; i++) {
      setPool(tokens[i], poolAddress[i], poolPercentage[i], notificationType[i], vests[i]);
    }
  }

  /// Pool management, adds, updates or removes a transfer/notification
  function setPool(
    address token,
    address poolAddress,
    uint256 poolPercentage,
    NotificationType notificationType,
    bool vests
  ) public onlyChanger {
    if (token == farm) {
      require(notificationType != NotificationType.TOKEN, "With FARM, use FARM, AMPLIFARM, or TRANSFER");
    }
    if (notificationType == NotificationType.TOKEN) {
      // we use type translation so that we can use the same contract
      NotifyHelperStateful(tokenToHelper[token]).setPool(poolAddress, poolPercentage,
        NotifyHelperStateful.NotificationType(uint256(NotificationType.FARM)), vests);
    } else {
      NotifyHelperStateful(tokenToHelper[token]).setPool(poolAddress, poolPercentage,
        NotifyHelperStateful.NotificationType(uint256(notificationType)), vests);
    }
    emit PoolChanged(poolAddress, poolPercentage, uint256(notificationType), vests);
  }

  /// emergency draining of tokens and ETH as there should be none staying here
  function emergencyDrain(address token, uint256 amount) public onlyGovernance {
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    }
  }

  /// Configuration method for vesting for governance
  function setVestingEscrow(address token, address _escrow) external onlyGovernance {
    NotifyHelperStateful(tokenToHelper[token]).setVestingEscrow(_escrow);
  }

  /// Configuration method for vesting for governance
  function setVesting(address token, uint256 _numerator, uint256 _denominator) external onlyGovernance {
    NotifyHelperStateful(tokenToHelper[token]).setVesting(_numerator, _denominator);
  }

  function notificationExists(address token, address poolAddress) public view returns(bool) {
    return NotifyHelperStateful(tokenToHelper[token]).notificationExists(poolAddress);
  }

  /// Returning the governance
  function transferGovernance(address target, address newStorage) external onlyGovernance {
    Governable(target).setStorage(newStorage);
  }

  /// The governance configures whitelists
  function setChanger(address who, bool value) external onlyGovernance {
    changer[who] = value;
    emit ChangerSet(who, value);
  }

  /// The governance configures whitelists
  function setNotifier(address who, bool value) external onlyGovernance {
    notifier[who] = value;
    emit NotifierSet(who, value);
  }
}

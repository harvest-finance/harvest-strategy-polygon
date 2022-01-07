// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./inheritance/Controllable.sol";
import "./PotPool.sol";

interface INotifyHelperGeneric {
  function feeRewardForwarder() external view returns (address);

  function notifyPools(uint256[] calldata amounts,
    address[] calldata pools,
    uint256 sum, address token
  ) external;
}

interface INotifyHelperAmpliFARM {
  function notifyPools(uint256[] calldata amounts,
    address[] calldata pools,
    uint256 sum
  ) external;
}

contract NotifyHelperStateful is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event ChangerSet(address indexed account, bool value);
  event NotifierSet(address indexed account, bool value);
  event Vesting(address pool, uint256 amount);
  event PoolChanged(address indexed pool, uint256 percentage, uint256 notificationType, bool vests);

  enum NotificationType {
    VOID, AMPLIFARM, FARM, TRANSFER, PROFIT_SHARE, TOKEN
  }

  struct Notification {
    address poolAddress;
    NotificationType notificationType;
    uint256 percentage;
    bool vests;
  }

  struct WorkingNotification {
    address[] pools;
    uint256[] amounts;
    uint256 checksum;
    uint256 counter;
  }

  uint256 public VESTING_DENOMINATOR = 3;
  uint256 public VESTING_NUMERATOR = 2;

  mapping (address => bool) changer;
  mapping (address => bool) notifier;

  address public notifyHelperRegular;
  address public notifyHelperAmpliFARM;
  address public rewardToken;

  Notification[] public notifications;
  mapping (address => uint256) public poolToIndex;
  mapping (uint256 => uint256) public numbers; // NotificationType to the number of pools

  address public reserve;
  address public vestingEscrow;
  uint256 public totalPercentage; // maintain state to not have to calculate during emissions

  modifier onlyChanger {
    require(changer[msg.sender] || msg.sender == governance(), "Only changer");
    _;
  }

  modifier onlyNotifier {
    require(notifier[msg.sender], "Only notifier");
    _;
  }

  constructor(address _storage,
    address _notifyHelperRegular,
    address _rewardToken,
    address _notifyHelperAmpliFARM,
    address _escrow,
    address _reserve)
  Controllable(_storage) public {
    // used for getting a reference to FeeRewardForwarder
    notifyHelperRegular = _notifyHelperRegular;
    rewardToken = _rewardToken;
    notifyHelperAmpliFARM = _notifyHelperAmpliFARM;
    vestingEscrow = _escrow;
    reserve = _reserve;
    require(_reserve != address(0), "invalid reserve");
    require(_escrow != address(0), "invalid escrow");
  }

  /// Whitelisted entities can notify pools based on the state, both for FARM and iFARM
  /// The only whitelisted entity here would be the minter helper
  function notifyPools(uint256 total, uint256 timestamp) public onlyNotifier {
    // transfer the tokens from the msg.sender to here
    IERC20Upgradeable(rewardToken).safeTransferFrom(msg.sender, address(this), total);

    // prepare the notification data
    WorkingNotification memory ampliFARM = WorkingNotification(
      new address[](numbers[uint256(NotificationType.AMPLIFARM)]),
      new uint256[](numbers[uint256(NotificationType.AMPLIFARM)]),
      0,
      0
    );
    WorkingNotification memory regular = WorkingNotification(
      new address[](numbers[uint256(NotificationType.FARM)]),
      new uint256[](numbers[uint256(NotificationType.FARM)]),
      0,
      0
    );
    uint256 vestingAmount = 0;
    for (uint256 i = 0; i < notifications.length; i++) {
      Notification storage notification = notifications[i];
      if (notification.notificationType == NotificationType.TRANSFER) {
        // simple transfer
        IERC20Upgradeable(rewardToken).safeTransfer(
          notification.poolAddress,
          total.mul(notification.percentage).div(totalPercentage)
        );
      } else {
        // FARM or ampliFARM notification
        WorkingNotification memory toUse = notification.notificationType == NotificationType.FARM ? regular : ampliFARM;
        toUse.amounts[toUse.counter] = total.mul(notification.percentage).div(totalPercentage);
        if (notification.vests) {
          uint256 toVest = toUse.amounts[toUse.counter].mul(VESTING_NUMERATOR).div(VESTING_DENOMINATOR);
          toUse.amounts[toUse.counter] = toUse.amounts[toUse.counter].sub(toVest);
          vestingAmount = vestingAmount.add(toVest);
          emit Vesting(notification.poolAddress, toVest);
        }
        toUse.pools[toUse.counter] = notification.poolAddress;
        toUse.checksum = toUse.checksum.add(toUse.amounts[toUse.counter]);
        toUse.counter = toUse.counter.add(1);
      }
    }

    // handle vesting
    if (vestingAmount > 0) {
      IERC20Upgradeable(rewardToken).safeTransfer(vestingEscrow, vestingAmount);
    }

    // ampliFARM notifications
    if (ampliFARM.checksum > 0) {
      IERC20Upgradeable(rewardToken).approve(notifyHelperAmpliFARM, ampliFARM.checksum);
      INotifyHelperAmpliFARM(notifyHelperAmpliFARM).notifyPools(ampliFARM.amounts, ampliFARM.pools, ampliFARM.checksum);
    }

    // regular notifications
    if (regular.checksum > 0) {
      IERC20Upgradeable(rewardToken).approve(notifyHelperRegular, regular.checksum);
      INotifyHelperGeneric(notifyHelperRegular).notifyPools(
        regular.amounts, regular.pools, regular.checksum, rewardToken
      );
    }

    // send rest to the reserve
    uint256 remainingBalance = IERC20Upgradeable(rewardToken).balanceOf(address(this));
    if (remainingBalance > 0) {
      IERC20Upgradeable(rewardToken).safeTransfer(reserve, remainingBalance);
    }
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

  /// Whitelisted entity makes changes to the notifications
  function setPoolBatch(address[] calldata poolAddress, uint256[] calldata poolPercentage, NotificationType[] calldata notificationType, bool[] calldata vests) external onlyChanger {
    for (uint256 i = 0; i < poolAddress.length; i++) {
      setPool(poolAddress[i], poolPercentage[i], notificationType[i], vests[i]);
    }
  }

  /// Pool management, adds, updates or removes a transfer/notification
  function setPool(address poolAddress, uint256 poolPercentage, NotificationType notificationType, bool vests) public onlyChanger {
    require(notificationType != NotificationType.VOID, "Use valid indication");
    require(notificationType != NotificationType.TOKEN, "We do not use TOKEN here");
    if (notificationExists(poolAddress) && poolPercentage == 0) {
      // remove
      removeNotification(poolAddress);
    } else if (notificationExists(poolAddress)) {
      // update
      updateNotification(poolAddress, notificationType, poolPercentage, vests);
    } else if (poolPercentage > 0) {
      // add because it does not exist
      addNotification(poolAddress, poolPercentage, notificationType, vests);
    }
    emit PoolChanged(poolAddress, poolPercentage, uint256(notificationType), vests);
  }

  /// Configuration method for vesting for governance
  function setVestingEscrow(address _escrow) external onlyGovernance {
    vestingEscrow = _escrow;
  }

  /// Configuration method for vesting for governance
  function setVesting(uint256 _numerator, uint256 _denominator) external onlyGovernance {
    VESTING_DENOMINATOR = _numerator;
    VESTING_NUMERATOR = _denominator;
  }

  function notificationExists(address poolAddress) public view returns(bool) {
    if (notifications.length == 0) return false;
    if (poolToIndex[poolAddress] != 0) return true;
    return (notifications[0].poolAddress == poolAddress);
  }

  function removeNotification(address poolAddress) internal {
    require(notificationExists(poolAddress), "notification does not exist");
    uint256 index = poolToIndex[poolAddress];
    Notification storage notification = notifications[index];

    totalPercentage = totalPercentage.sub(notification.percentage);
    numbers[uint256(notification.notificationType)] = numbers[uint256(notification.notificationType)].sub(1);

    // move the last element here and pop from the array
    notifications[index] = notifications[notifications.length.sub(1)];
    poolToIndex[notifications[index].poolAddress] = index;
    poolToIndex[poolAddress] = 0;
    notifications.pop();
  }

  function updateNotification(address poolAddress, NotificationType notificationType, uint256 percentage, bool vesting) internal {
    require(notificationExists(poolAddress), "notification does not exist");
    require(percentage > 0, "notification is 0");
    uint256 index = poolToIndex[poolAddress];
    totalPercentage = totalPercentage.sub(notifications[index].percentage).add(percentage);
    notifications[index].percentage = percentage;
    notifications[index].vests = vesting;
    if (notifications[index].notificationType != notificationType) {
      numbers[uint256(notifications[index].notificationType)] = numbers[uint256(notifications[index].notificationType)].sub(1);
      notifications[index].notificationType = notificationType;
      numbers[uint256(notifications[index].notificationType)] = numbers[uint256(notifications[index].notificationType)].add(1);
    }
  }

  function addNotification(address poolAddress, uint256 percentage, NotificationType notificationType, bool vesting) internal {
    require(!notificationExists(poolAddress), "notification exists");
    require(percentage > 0, "notification is 0");
    require(PotPool(poolAddress).getRewardTokenIndex(rewardToken) != uint256(-1), "Token not configured on pot pool");
    Notification memory notification = Notification(poolAddress, notificationType, percentage, vesting);
    notifications.push(notification);
    totalPercentage = totalPercentage.add(notification.percentage);
    numbers[uint256(notification.notificationType)] = numbers[uint256(notification.notificationType)].add(1);
    poolToIndex[notification.poolAddress] = notifications.length.sub(1);
    require(notificationExists(poolAddress), "notification was not added");
  }

  /// emergency draining of tokens and ETH as there should be none staying here
  function emergencyDrain(address token, uint256 amount) public onlyGovernance {
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    }
  }

  function getConfig(uint256 totalAmount) external view returns(address[] memory, uint256[] memory, uint256[] memory) {
    address[] memory pools = new address[](notifications.length);
    uint256[] memory percentages = new uint256[](notifications.length);
    uint256[] memory amounts = new uint256[](notifications.length);
    for (uint256 i = 0; i < notifications.length; i++) {
      Notification storage notification = notifications[i];
      pools[i] = notification.poolAddress;
      percentages[i] = notification.percentage.mul(1000000).div(totalPercentage);
      amounts[i] = notification.percentage.mul(totalAmount).div(totalPercentage);
    }
    return (pools, percentages, amounts);
  }
}

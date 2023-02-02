// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
  enum RaffleState {
    OPEN,
    CALCULATING
  }

  VRFCoordinatorV2Interface private immutable vrfCoordinator;
  bytes32 private immutable gasLane;
  uint64 private immutable subscriptionId;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private immutable callbackGasLimit;
  uint16 private constant NUM_WORDS = 1;

  uint256 private immutable entranceFee;
  address payable[] private players;
  address private recentWinner;
  RaffleState private raffleState;
  uint256 private lastTimestamp;
  uint256 private immutable interval;

  event RaffleEnter(address indexed player);
  event RequestedRaffleWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed winner);

  constructor(
    address _vrfCoordinator,
    uint256 _entranceFee,
    bytes32 _gasLane,
    uint64 _subscriptionId,
    uint32 _callbackGasLimit,
    uint256 _interval
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    entranceFee = _entranceFee;
    vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    gasLane = _gasLane;
    subscriptionId = _subscriptionId;
    callbackGasLimit = _callbackGasLimit;
    raffleState = RaffleState.OPEN;
    lastTimestamp = block.timestamp;
    interval = _interval;
  }

  function enterRaffle() public payable {
    if (msg.value < entranceFee) {
      revert Raffle__NotEnoughETHEntered();
    }
    if (raffleState != RaffleState.OPEN) {
      revert Raffle__NotOpen();
    }
    players.push(payable(msg.sender));
    emit RaffleEnter(msg.sender);
  }

  function checkUpkeep(
    bytes memory /* checkData */
  ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
    bool isOpen = raffleState == RaffleState.OPEN;
    bool timePassed = (block.timestamp - lastTimestamp) > interval;
    bool hasPlayers = players.length > 0;
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
    return (upkeepNeeded, "");
  }

  function performUpkeep(bytes calldata /* performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if (!upkeepNeeded) {
      revert Raffle__UpkeepNotNeeded(address(this).balance, players.length, uint256(raffleState));
    }

    raffleState = RaffleState.CALCULATING;
    uint256 requestId = vrfCoordinator.requestRandomWords(
      gasLane,
      subscriptionId,
      REQUEST_CONFIRMATIONS,
      callbackGasLimit,
      NUM_WORDS
    );
    emit RequestedRaffleWinner(requestId);
  }

  function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
    uint256 indexOfWinner = randomWords[0] % players.length;
    recentWinner = players[indexOfWinner];
    players = new address payable[](0);
    raffleState = RaffleState.OPEN;
    lastTimestamp = block.timestamp;
    (bool success, ) = recentWinner.call{value: address(this).balance}("");
    if (!success) {
      revert Raffle__TransferFailed();
    }
    emit WinnerPicked(recentWinner);
  }

  function getEntranceFee() public view returns (uint256) {
    return entranceFee;
  }

  function getPlayer(uint256 index) public view returns (address) {
    return players[index];
  }

  function getRecentWinner() public view returns (address) {
    return recentWinner;
  }

  function getRaffleState() public view returns (RaffleState) {
    return raffleState;
  }

  function getNumWords() public pure returns (uint256) {
    return NUM_WORDS;
  }

  function getNumberOfPlayers() public view returns (uint256) {
    return players.length;
  }

  function getLatestTimestamp() public view returns (uint256) {
    return lastTimestamp;
  }

  function getRequestConfirmations() public pure returns (uint256) {
    return REQUEST_CONFIRMATIONS;
  }

  function getInterval() public view returns (uint256) {
    return interval;
  }
}

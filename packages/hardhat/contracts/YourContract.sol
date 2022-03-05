//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YourContract is VRFConsumerBaseV2, Ownable {

  event Register(address indexed origin, address indexed yourContract);
  event Move(address indexed origin, string indexed move, uint256 indexed healthLeft);

  struct PlayerMove {
    address player;
    string move;
  }

  VRFCoordinatorV2Interface immutable coordinator;
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  uint64 immutable subscriptionId;
  bytes32 immutable keyHash;
  uint32 immutable callbackGasLimit;
  uint16 immutable requestConfirmations;
  uint32 immutable numWords;
  bool public gameOn;
  uint256 public startTime;

  mapping(address => address) public yourContract;
  mapping(address => uint256) public health;
  mapping(address => string) public moves;
  mapping(address => uint256) public last;
  mapping(uint256 => PlayerMove) public requestIds;

  constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    subscriptionId = _subscriptionId;
    // params for Rinkeby
    coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    callbackGasLimit = 100000;
    requestConfirmations = 3;
    numWords = 1;
  }


  function register() public {
    require(!gameOn, "TOO LATE");
    require(tx.origin != msg.sender, "NOT A CONTRACT");
    require(yourContract[tx.origin] == address(0), "NO MORE PLZ");

    yourContract[tx.origin] = msg.sender;
    health[tx.origin] = 5000;

    emit Register(tx.origin,msg.sender);
  }


  function start() public onlyOwner {
    gameOn = true;
    startTime = block.timestamp;
  }


  function move(string calldata yourMove) public {
    require(gameOn, "NOT YET");
    require(tx.origin != msg.sender, "NOT A CONTRACT");
    require(msg.sender == yourContract[tx.origin], "STOP LARPING");
    require(health[tx.origin] > 0, "YOU DED");
    require((block.timestamp < startTime + 120 && last[tx.origin] == 0) || block.timestamp > last[tx.origin] + 10, "YOU CANT THO");
    require((block.timestamp < startTime + 120 && last[tx.origin] == 0) || block.timestamp < last[tx.origin] + 60, "YOU OUT THO");

    uint256 requestId = coordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);

    requestIds[requestId] = PlayerMove(tx.origin, yourMove);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    uint256 randomNumber = (randomWords[0] % 200) + 1;

    address playerOnMove = requestIds[requestId].player;
    string memory yourMove = requestIds[requestId].move;

    health[playerOnMove] -= randomNumber;
    moves[playerOnMove] = yourMove;
    last[playerOnMove] = block.timestamp;

    emit Move(playerOnMove, yourMove, health[playerOnMove]);
  }

}

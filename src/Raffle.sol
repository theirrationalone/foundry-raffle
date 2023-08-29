// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__NotPaidEnoughEntranceFee(uint256 _feePaid, uint256 _feeRequired);
    error Raffle__RaffleStateNotOpen(uint256 _raffleState);
    error Raffle__UpkeepNotNeeded(uint256 raffleBalance, uint256 raffleState, uint256 entrantsLength);
    error Raffle__RewardPaymentFailedUnexpectedly();

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinatorV2;
    uint256 private immutable i_entranceFee;
    address payable[] private s_entrants;
    uint256 private immutable i_interval;
    uint256 private s_lastTimestamp;
    RaffleState private s_raffleState;
    address payable private s_recentWinner;

    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant MINIMUM_REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    event RaffleEnter(address indexed _entrant, uint256 indexed _entranceFeed);
    event RandomWinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address _vrfCoordinatorV2Address,
        uint256 _entranceFee,
        bytes32 _gasLane,
        uint64 _subId,
        uint32 _callbackGasLimit,
        uint256 _interval
    ) VRFConsumerBaseV2(_vrfCoordinatorV2Address) {
        i_vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2Address);
        i_entranceFee = _entranceFee;

        i_gasLane = _gasLane;
        i_subId = _subId;
        i_callbackGasLimit = _callbackGasLimit;

        i_interval = _interval;
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        uint256 currentRaffleState = uint256(s_raffleState);
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleStateNotOpen(currentRaffleState);
        }

        if (msg.value < i_entranceFee) {
            revert Raffle__NotPaidEnoughEntranceFee(msg.value, i_entranceFee);
        }

        s_entrants.push(payable(msg.sender));
        emit RaffleEnter(msg.sender, msg.value);
    }

    function checkUpkeep(bytes memory) public view override returns (bool upkeepNeeded, bytes memory) {
        bool hasBalance = address(this).balance > 0;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasEntrants = s_entrants.length > 0;
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_interval;
        upkeepNeeded = (hasBalance && isOpen && hasEntrants && timePassed);

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded,) = checkUpkeep("");

        uint256 currentRaffleState = uint256(s_raffleState);
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, currentRaffleState, s_entrants.length);
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = i_vrfCoordinatorV2.requestRandomWords(
            i_gasLane, i_subId, MINIMUM_REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );

        emit RandomWinnerRequested(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 winnerIdx = randomWords[0] % s_entrants.length;
        address payable winner = s_entrants[winnerIdx];

        s_recentWinner = winner;
        s_entrants = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;

        emit WinnerPicked(s_recentWinner);

        (bool isSuccess,) = s_recentWinner.call{value: address(this).balance}("");

        if (!isSuccess) {
            revert Raffle__RewardPaymentFailedUnexpectedly();
        }
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getVRFCoordinatorV2Address() public view returns (address) {
        return address(i_vrfCoordinatorV2);
    }

    function getEntrant(uint256 _entrantIdx) public view returns (address) {
        return s_entrants[_entrantIdx];
    }

    function getEntrantsLength() public view returns (uint256) {
        return s_entrants.length;
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getSubId() public view returns (uint64) {
        return i_subId;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return i_callbackGasLimit;
    }

    function getMinimumRequestConfirmations() public pure returns (uint16) {
        return MINIMUM_REQUEST_CONFIRMATIONS;
    }

    function getNumWords() public pure returns (uint32) {
        return NUM_WORDS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getLastTimestamp() public view returns (uint256) {
        return s_lastTimestamp;
    }

    function getRaffleState() public view returns (uint256) {
        return uint256(s_raffleState);
    }

    function getWinner() public view returns (address) {
        return s_recentWinner;
    }
}

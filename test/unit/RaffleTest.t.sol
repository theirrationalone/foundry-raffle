// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleTest is Test {
    Raffle private s_raffle;
    address private s_vrfCoordinatorV2Address;
    uint256 private s_entranceFee;
    bytes32 private s_gasLane;
    uint64 private s_subId;
    uint32 private s_callbackGasLimit;
    uint256 private s_interval;

    address ENTRANT = makeAddr("entrant");
    uint256 private constant STARTING_BALANCE = 10 ether;

    event RaffleEnter(address indexed _entrant, uint256 indexed _entranceFee);
    event RandomWinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        HelperConfig config;
        DeployRaffle deployer = new DeployRaffle();
        (s_raffle, config) = deployer.run();
        (s_vrfCoordinatorV2Address, s_entranceFee, s_gasLane, s_subId, s_callbackGasLimit, s_interval,,) =
            config.activeNetworkConfig();

        vm.deal(ENTRANT, STARTING_BALANCE);
    }

    modifier EnteredIntoLotteryAndTimePassed() {
        vm.startPrank(ENTRANT);
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();

        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testHasInitializedNumWordsCorrectly() public {
        uint32 expectedNumWords = 1;
        uint32 actualNumWords = s_raffle.getNumWords();

        assertEq(actualNumWords, expectedNumWords);
    }

    function testHasInitializedMinimumRequestConfirmationsCorrectly() public {
        uint16 expectedMinimumRequestConfirmations = 3;
        uint16 actualMinimumRequestConfirmations = s_raffle.getMinimumRequestConfirmations();

        assertEq(actualMinimumRequestConfirmations, expectedMinimumRequestConfirmations);
    }

    function testSetsEntranceFeeCorrectly() public {
        uint256 actualEntranceFee = s_raffle.getEntranceFee();

        assertEq(actualEntranceFee, s_entranceFee);
    }

    function testSetsVRFCoordinatorV2Correctly() public {
        address actualVrfCoordinatorV2Address = s_raffle.getVRFCoordinatorV2Address();

        assertEq(actualVrfCoordinatorV2Address, s_vrfCoordinatorV2Address);
    }

    function testSetsGasLaneCorrectly() public {
        bytes32 actualGasLane = s_raffle.getGasLane();

        assertEq(actualGasLane, s_gasLane);
    }

    function testSetsSubscriptionIdCorrectly() public {
        uint64 actualSubscriptionId = s_raffle.getSubId();

        if (s_subId == 0) {
            assert(s_subId != actualSubscriptionId);
            assert(actualSubscriptionId > 0);
        } else {
            assertEq(actualSubscriptionId, s_subId);
        }
    }

    function testSetsCallbackGasLimitCorrectly() public {
        uint32 actualCallbackGasLimit = s_raffle.getCallbackGasLimit();

        assertEq(actualCallbackGasLimit, s_callbackGasLimit);
    }

    function testSetsIntervalCorrectly() public {
        uint256 actualInterval = s_raffle.getInterval();

        assertEq(actualInterval, s_interval);
    }

    function testRaffleHasOpenStateIntially() public {
        uint256 expectedRaffleState = 0;
        uint256 actualRaffleState = s_raffle.getRaffleState();

        assertEq(actualRaffleState, expectedRaffleState);
    }

    function testRaffleHasCorrectTimestamp() public view {
        uint256 actualRaffleTimestamp = s_raffle.getLastTimestamp();

        assert(block.timestamp >= actualRaffleTimestamp);
    }

    function testRaffleHasNoWinnerInitially() public {
        address expectedWinner = address(0);
        address actualWinner = s_raffle.getWinner();

        assertEq(actualWinner, expectedWinner);
    }

    function testRaffleHasNoPlayersInitially() public {
        uint256 expectedEntrantsLength = 0;
        uint256 actualEntrantsLength = s_raffle.getEntrantsLength();

        assertEq(actualEntrantsLength, expectedEntrantsLength);

        vm.expectRevert();
        s_raffle.getEntrant(0);
    }

    function testEntrantCouldNotEnterIntoLotteryWithInsufficientEntranceFee() public {
        uint256 invalidEntranceFee = s_entranceFee - 0.0001 ether;

        vm.startPrank(ENTRANT);
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__NotPaidEnoughEntranceFee.selector, invalidEntranceFee, s_entranceFee)
        );
        s_raffle.enterRaffle{value: invalidEntranceFee}();
        vm.stopPrank();
    }

    function testEntrantCouldNotEnterIntoLotteryIfLotteryIsNotOpen() public {
        vm.startPrank(ENTRANT);
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();

        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        s_raffle.performUpkeep("");

        vm.startPrank(ENTRANT);
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__RaffleStateNotOpen.selector, 1));
        s_raffle.enterRaffle{value: 0}();
        vm.stopPrank();

        assertEq(s_raffle.getRaffleState(), 1);
    }

    function testEntrantCanEnterIntoLotteryIfLotteryIsInOpenStateWithSufficientEntranceFee() public {
        vm.startPrank(ENTRANT);
        s_raffle.enterRaffle{value: s_entranceFee}();

        assertEq(s_raffle.getEntrantsLength(), 1);
        assertEq(s_raffle.getEntrant(0), ENTRANT);
        vm.stopPrank();
    }

    function testLotteryEmitsAnEventOnEntrantEntry() public {
        vm.startPrank(ENTRANT);
        vm.expectEmit(true, true, false, false, address(s_raffle));
        emit RaffleEnter(ENTRANT, s_entranceFee);
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();
    }

    function testVerifiesRaffleTestRaffleEnterEventData() public {
        vm.startPrank(ENTRANT);
        vm.recordLogs();
        vm.expectEmit(true, true, false, false, address(s_raffle));
        emit RaffleEnter(ENTRANT, s_entranceFee);
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 playerProto = entries[0].topics[1];
        bytes32 playerFeeProto = entries[0].topics[2];

        address player = address(uint160(uint256(playerProto)));
        uint256 playerFee = uint256(playerFeeProto);

        assertEq(player, ENTRANT);
        assertEq(playerFee, s_entranceFee);
    }

    function testVerifiesRaffleEnterEventData() public {
        vm.startPrank(ENTRANT);
        vm.recordLogs();
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 playerProto = entries[0].topics[1];
        bytes32 playerFeeProto = entries[0].topics[2];

        address player = address(uint160(uint256(playerProto)));
        uint256 playerFee = uint256(playerFeeProto);

        assertEq(player, ENTRANT);
        assertEq(playerFee, s_entranceFee);
    }

    function testCheckUpkeepReturnsFalseIfLotteryHasNoBalance() public {
        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = s_raffle.checkUpkeep("0x0");

        assertEq(upkeepNeeded, false);
        assertEq(address(s_raffle).balance, 0);
    }

    function testCheckUpkeepReturnsFalseIfLotteryHasNoPlayers() public {
        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = s_raffle.checkUpkeep("0x0");

        assertEq(upkeepNeeded, false);
        assertEq(s_raffle.getEntrantsLength(), 0);
    }

    function testcheckUpkeepReturnsFalseIfEnoughTimeNotPassed() public {
        vm.startPrank(ENTRANT);
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();

        (bool upkeepNeeded,) = s_raffle.checkUpkeep("0x0");

        assertEq(upkeepNeeded, false);
        assertEq(address(s_raffle).balance, s_entranceFee);
        assertEq(s_raffle.getEntrantsLength(), 1);
        assert(s_raffle.getLastTimestamp() < s_raffle.getLastTimestamp() + s_interval);
    }

    function testCheckUpkeepReturnsFalseIfLotteryIsNotInOpenState() public EnteredIntoLotteryAndTimePassed {
        s_raffle.performUpkeep("0x0");
        (bool upkeepNeeded,) = s_raffle.checkUpkeep("0x0");

        assertEq(upkeepNeeded, false);
        assertEq(address(s_raffle).balance, s_entranceFee);
        assertEq(s_raffle.getRaffleState(), 1);
        assertEq(s_raffle.getEntrantsLength(), 1);
        assert(s_raffle.getLastTimestamp() <= block.timestamp + s_interval);
    }

    function testCheckUpkeepReturnsTrue() public EnteredIntoLotteryAndTimePassed {
        (bool upkeepNeeded,) = s_raffle.checkUpkeep("0x0");

        assertEq(upkeepNeeded, true);
        assertEq(address(s_raffle).balance, s_entranceFee);
        assertEq(s_raffle.getEntrantsLength(), 1);
        assertEq(s_raffle.getRaffleState(), 0);
    }

    function testPerformUpkeepSetsLotteryStateToCalculatingIfCheckUpkeepReturnsTrue()
        public
        EnteredIntoLotteryAndTimePassed
    {
        (bool upkeepNeeded,) = s_raffle.checkUpkeep("0x0");
        s_raffle.performUpkeep("0x0");

        assertEq(upkeepNeeded, true);
        assertEq(s_raffle.getRaffleState(), 1);
    }

    function testPerformUpkeepRevertsExecutionIfCheckUpkeepReturnsFalse() public {
        uint256 raffleBalance = address(s_raffle).balance;
        uint256 raffleState = s_raffle.getRaffleState();
        uint256 entrantsLength = s_raffle.getEntrantsLength();

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, raffleBalance, raffleState, entrantsLength)
        );
        s_raffle.performUpkeep("0x0");
    }

    function testPerformUPkeepRevertsIfLotteryIsInCalculatingState() public EnteredIntoLotteryAndTimePassed {
        s_raffle.performUpkeep("0x0");

        uint256 raffleBalance = address(s_raffle).balance;
        uint256 raffleState = s_raffle.getRaffleState();
        uint256 entrantsLength = s_raffle.getEntrantsLength();

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, raffleBalance, raffleState, entrantsLength)
        );
        s_raffle.performUpkeep("0x0");
    }

    function testPerformUpkeepRevertsIfEnoughTimeNotPassed() public {
        vm.startPrank(ENTRANT);
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();

        uint256 raffleBalance = address(s_raffle).balance;
        uint256 raffleState = s_raffle.getRaffleState();
        uint256 entrantsLength = s_raffle.getEntrantsLength();
        uint256 lastTimestamp = s_raffle.getLastTimestamp();

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, raffleBalance, raffleState, entrantsLength)
        );
        s_raffle.performUpkeep("0x0");

        assert(lastTimestamp < (lastTimestamp + s_interval));
    }

    function testPerformUpkeepEmitsAnEventOnSuccessfulExecution() public EnteredIntoLotteryAndTimePassed {
        vm.expectEmit(true, false, false, false, address(s_raffle));
        emit RandomWinnerRequested(1);
        s_raffle.performUpkeep("0x0");
    }

    function testVerifyPerformUpkeepTestEmittedEventDataIsCorrect() public EnteredIntoLotteryAndTimePassed {
        vm.recordLogs();
        vm.expectEmit(true, false, false, false, address(s_raffle));
        emit RandomWinnerRequested(1);
        s_raffle.performUpkeep("0x0");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[0].topics[1];
        uint256 requestId = uint256(requestIdProto);

        assertEq(requestId, 1);
    }

    function testVerifyPerformUpkeepEmittedEventDataIsCorrect() public EnteredIntoLotteryAndTimePassed {
        vm.recordLogs();
        s_raffle.performUpkeep("0x0");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[1].topics[1];
        uint256 requestId = uint256(requestIdProto);

        assertEq(requestId, 1);
    }

    function testFulfillRandomWordsRevertsMock() public EnteredIntoLotteryAndTimePassed {
        vm.recordLogs();
        s_raffle.performUpkeep("0x0");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[1].topics[1];
        uint256 requestId = uint256(requestIdProto);

        vm.mockCallRevert(
            s_vrfCoordinatorV2Address,
            abi.encodeWithSignature("fulfillRandomWords(uint256,address)", requestId, address(s_raffle)),
            abi.encodeWithSelector(Raffle.Raffle__RewardPaymentFailedUnexpectedly.selector)
        );
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__RewardPaymentFailedUnexpectedly.selector));
        VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address).fulfillRandomWords(requestId, address(s_raffle));
    }

    function testFulfillRandomWordsRevertsMockForVRFMock() public EnteredIntoLotteryAndTimePassed {
        vm.recordLogs();
        s_raffle.performUpkeep("0x0");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[1].topics[1];
        uint256 requestId = uint256(requestIdProto);

        vm.mockCallRevert(
            s_vrfCoordinatorV2Address,
            abi.encodeWithSignature("fulfillRandomWords(uint256,address)", requestId, address(s_raffle)),
            "nonexistent request"
        );
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address).fulfillRandomWords(requestId, address(s_raffle));
    }

    function testFulfillRandomWordsRevertsFuzzed(uint256 requestSeed) public EnteredIntoLotteryAndTimePassed {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address).fulfillRandomWords(requestSeed, address(s_raffle));
    }

    function testCannotExecuteFulfillRandomWordsDirectlyOutsideFromLottery() public {
        vm.startPrank(ENTRANT);
        s_raffle.enterRaffle{value: s_entranceFee}();
        vm.stopPrank();

        vm.startPrank(ENTRANT);
        (bool success,) =
            address(s_raffle).call(abi.encodeWithSignature("fulfillRandomWords(uint256,uint256[])", 1, [223434433242]));
        vm.stopPrank();

        assertEq(success, false);
        assertEq(s_raffle.getWinner(), address(0));
    }

    function testFulfillRandomWordsGivesAWinnerAndResetsLottery() public EnteredIntoLotteryAndTimePassed {
        vm.recordLogs();
        s_raffle.performUpkeep("0x0");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[1].topics[1];
        uint256 requestId = uint256(requestIdProto);

        uint256 startingRaffleBalance = address(s_raffle).balance;
        uint256 winnerStartingBalance = ENTRANT.balance;
        uint256 lastTimestamp = s_raffle.getLastTimestamp();

        VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address).fulfillRandomWords(requestId, address(s_raffle));

        uint256 winnerEndingBalance = ENTRANT.balance;

        assertEq(s_raffle.getWinner(), ENTRANT);
        assertEq(s_raffle.getRaffleState(), 0);
        assertEq(s_raffle.getEntrantsLength(), 0);
        assertEq(address(s_raffle).balance, 0);
        assertEq(startingRaffleBalance, s_entranceFee);
        assertEq(winnerEndingBalance, winnerStartingBalance + s_entranceFee);
        assert(lastTimestamp < s_raffle.getLastTimestamp());
        assert(startingRaffleBalance > address(s_raffle).balance);
    }

    function testFulfillRandomWordsGivesAWinnerFromMultipleEntrantsAndResetsLottery()
        public
        EnteredIntoLotteryAndTimePassed
    {
        uint256 extraEntrants = 6;
        for (uint160 i = 1; i < extraEntrants; i++) {
            hoax(address(i), STARTING_BALANCE);
            s_raffle.enterRaffle{value: s_entranceFee}();
        }

        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);

        assertEq(s_raffle.getEntrantsLength(), 6);
        assertEq(address(s_raffle).balance, (s_entranceFee * extraEntrants));
        assertEq(s_raffle.getRaffleState(), 0);

        vm.recordLogs();
        s_raffle.performUpkeep("0x0");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[1].topics[1];
        uint256 requestId = uint256(requestIdProto);

        VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address).fulfillRandomWords(requestId, address(s_raffle));

        assertEq(s_raffle.getEntrantsLength(), 0);
        assertEq(address(s_raffle).balance, 0);
        assertEq(s_raffle.getRaffleState(), 0);
        assertEq(s_raffle.getWinner().balance, (STARTING_BALANCE + (s_entranceFee * 5)));
    }

    function testFulfillRandomWordsEmitsEventOnSuccessfulExecution() public EnteredIntoLotteryAndTimePassed {
        vm.recordLogs();
        s_raffle.performUpkeep("0x0");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[1].topics[1];
        uint256 requestId = uint256(requestIdProto);

        vm.expectEmit(true, false, false, false, address(s_raffle));
        emit WinnerPicked(ENTRANT);
        VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address).fulfillRandomWords(requestId, address(s_raffle));
    }
}

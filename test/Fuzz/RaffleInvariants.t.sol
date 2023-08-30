// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {RaffleHandler} from "./RaffleHandler.t.sol";

contract RaffleInvariants is StdInvariant, Test {
    Raffle raffle;

    function setUp() external {
        HelperConfig config = new HelperConfig();

        DeployRaffle deployer = new DeployRaffle();
        uint64 subId;
        (raffle, config, subId) = deployer.run();

        (address vrfCoordinatorV2Address,,,,,,, address linkTokenAddress) = config.activeNetworkConfig();

        RaffleHandler handler = new RaffleHandler(address(raffle), vrfCoordinatorV2Address, subId, linkTokenAddress);

        targetContract(address(handler));
    }

    function invariant_lotteryCanHaveOnlyOneWinnerInAnyWay() public {
        address winner = raffle.getWinner();

        assertEq(raffle.getRaffleState(), 0);
        assert(winner.balance >= address(raffle).balance);
    }

    function invariant_helperFunctionsMustNotRevert() public view {
        raffle.getCallbackGasLimit();
        raffle.getEntranceFee();
        raffle.getEntrantsLength();
        raffle.getGasLane();
        raffle.getInterval();
        raffle.getLastTimestamp();
        raffle.getMinimumRequestConfirmations();
        raffle.getNumWords();
        raffle.getRaffleState();
        raffle.getSubId();
        raffle.getVRFCoordinatorV2Address();
        raffle.getWinner();
    }
}

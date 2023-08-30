// SPDX-License-Identifer: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

import {Raffle} from "../../src/Raffle.sol";

contract RaffleHandler is Test {
    Raffle private immutable i_raffle;
    VRFCoordinatorV2Mock private immutable i_vrfCoordinator;
    address private immutable i_vrfCoordinatorV2Address;
    address private immutable i_linkTokenAddress;
    uint64 private immutable i_subId;

    constructor(address _raffleAddress, address _vrfCoordinatorV2Address, uint64 _subId, address _linkTokenAddress) {
        i_raffle = Raffle(payable(_raffleAddress));
        i_vrfCoordinatorV2Address = _vrfCoordinatorV2Address;
        i_linkTokenAddress = _linkTokenAddress;
        i_vrfCoordinator = VRFCoordinatorV2Mock(_vrfCoordinatorV2Address);
        i_subId = _subId;
    }

    function perforUpkeep(address _entrantSeed) public {
        uint256 entranceFee = 0.001 ether;

        if (i_raffle.getRaffleState() != 0) {
            return;
        }

        if (
            _entrantSeed == address(0) || _entrantSeed == i_vrfCoordinatorV2Address
                || _entrantSeed == i_linkTokenAddress
        ) {
            return;
        }

        hoax(_entrantSeed, entranceFee);
        i_raffle.enterRaffle{value: entranceFee}();

        for (uint160 i = 1; i <= 10; i++) {
            hoax(address(i), 10 ether);
            i_raffle.enterRaffle{value: entranceFee}();
        }

        vm.warp(block.timestamp + 31);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = i_raffle.checkUpkeep("0x0");

        if (!upkeepNeeded) {
            return;
        }

        vm.recordLogs();
        i_raffle.performUpkeep("0x0");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestIdProto = entries[1].topics[1];

        i_vrfCoordinator.fundSubscription(i_subId, 10 ether);
        i_vrfCoordinator.fulfillRandomWords(uint256(requestIdProto), address(i_raffle));
    }
}

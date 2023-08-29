// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig, uint64) {
        HelperConfig config = new HelperConfig();
        (
            address vrfCoordinatorV2Address,
            uint256 entranceFee,
            bytes32 gasLane,
            uint64 subId,
            uint32 callbackGasLimit,
            uint256 interval,
            uint256 privateKey,
            address linkTokenAddress
        ) = config.activeNetworkConfig();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(vrfCoordinatorV2Address, privateKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinatorV2Address, linkTokenAddress, subId, privateKey);
        }

        vm.startBroadcast(privateKey);
        Raffle raffle = new Raffle(vrfCoordinatorV2Address, entranceFee, gasLane, subId, callbackGasLimit, interval);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinatorV2Address, subId, privateKey);

        return (raffle, config, subId);
    }
}

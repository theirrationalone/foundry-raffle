// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.m.sol";

contract CreateSubscription is Script {
    function createSubscription(address _vrfCoordinatorV2Address, uint256 _deployerKey) public returns (uint64) {
        vm.startBroadcast(_deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinatorV2Address).createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function createSubscriptionUsingConfig() internal {
        HelperConfig config = new HelperConfig();
        (address vrfCoordinatorV2Address,,,,,, uint256 privateKey,) = config.activeNetworkConfig();

        createSubscription(vrfCoordinatorV2Address, privateKey);
    }

    function run() external {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    error FundSubscription__FailedToFundLinkToken();

    uint96 FUND_AMOUNT = 3 ether;

    function fundSubscription(
        address _vrfCoordinatorV2Address,
        address _linkTokenAddress,
        uint64 _subId,
        uint256 _deployerKey
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast(_deployerKey);
            VRFCoordinatorV2Mock(_vrfCoordinatorV2Address).fundSubscription(_subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(_deployerKey);
            bool success =
                LinkToken(_linkTokenAddress).transferAndCall(_vrfCoordinatorV2Address, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();

            if (!success) {
                revert FundSubscription__FailedToFundLinkToken();
            }
        }
    }

    function fundSubscriptionUsingConfig() internal {
        HelperConfig config = new HelperConfig();
        (address vrfCoordinatorV2Address,,, uint64 subId,,, uint256 privateKey, address linkTokenAddress) =
            config.activeNetworkConfig();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(vrfCoordinatorV2Address, privateKey);
        }

        fundSubscription(vrfCoordinatorV2Address, linkTokenAddress, subId, privateKey);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address _raffleAddress, address _vrfCoordinatorV2Address, uint64 _subId, uint256 _deployerKey)
        public
    {
        vm.startBroadcast(_deployerKey);
        VRFCoordinatorV2Mock(_vrfCoordinatorV2Address).addConsumer(_subId, _raffleAddress);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address _recentRaffleAddress) internal {
        HelperConfig config = new HelperConfig();
        (address vrfCoordinatorV2Address,,, uint64 subId,,, uint256 privateKey, address linkTokenAddress) =
            config.activeNetworkConfig();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(vrfCoordinatorV2Address, privateKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinatorV2Address, linkTokenAddress, subId, privateKey);
        }

        addConsumer(_recentRaffleAddress, vrfCoordinatorV2Address, subId, privateKey);
    }

    function run() external {
        address recentRaffleAddress = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);

        addConsumerUsingConfig(recentRaffleAddress);
    }
}

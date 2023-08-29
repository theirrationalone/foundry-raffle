// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract InteractionsTest is Test {
    address private s_raffleAddress;
    address private s_vrfCoordinatorV2Address;
    address private s_linkTokenAddress;
    uint64 private s_subId;
    uint256 private s_privateKey;

    function setUp() external {
        HelperConfig config;
        DeployRaffle deployer = new DeployRaffle();
        Raffle raffle;
        (raffle, config, s_subId) = deployer.run();
        s_raffleAddress = address(raffle);
        (s_vrfCoordinatorV2Address,,,,,, s_privateKey, s_linkTokenAddress) = config.activeNetworkConfig();
    }

    modifier skipTest() {
        // We already have DeployRaffle to perform procedure from Create Subscription to Add Consumer, on Real live chains (Test/Main).
        if (block.chainid != 31337) return;
        _;
    }

    function testCreateSubscriptionScriptWorksIndependently() public skipTest {
        CreateSubscription createSubscription = new CreateSubscription();

        createSubscription.run();
    }

    function testFundSubscriptionScriptWorksIndependently() public skipTest {
        FundSubscription fundSubscription = new FundSubscription();

        fundSubscription.run();
    }

    function testaddConsumerScriptWorksIndependently() public skipTest {
        AddConsumer addConsumer = new AddConsumer();

        addConsumer.run();
    }

    function testInteractionsScriptContractsWorksInterdependently() public {
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address);

        CreateSubscription createSubscription = new CreateSubscription();
        uint64 newSubId = createSubscription.createSubscription(s_vrfCoordinatorV2Address, s_privateKey);

        (uint96 balance,,, address[] memory consumers) = vrfCoordinator.getSubscription(newSubId);

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(s_vrfCoordinatorV2Address, s_linkTokenAddress, newSubId, s_privateKey);

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(s_raffleAddress, s_vrfCoordinatorV2Address, newSubId, s_privateKey);

        (uint96 updatedBalance,,, address[] memory updatedConsumers) = vrfCoordinator.getSubscription(newSubId);

        assert(newSubId != s_subId);
        assert(newSubId > 0);
        assert(updatedConsumers.length > consumers.length);
        assert(updatedBalance > balance);
        assertEq(balance, 0);
        assertEq(updatedBalance, 3 ether);
        assertEq(consumers.length, 0);
        assertEq(updatedConsumers.length, 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract InteractionsTest is Test {
    address private s_vrfCoordinatorV2Address;
    address private s_linkTokenAddress;
    uint64 private s_subId;
    uint256 private s_privateKey;

    function setUp() external {
        HelperConfig config;
        DeployRaffle deployer = new DeployRaffle();
        (, config, s_subId) = deployer.run();
        (s_vrfCoordinatorV2Address,,,,,, s_privateKey, s_linkTokenAddress) = config.activeNetworkConfig();
    }

    modifier skipTest() {
        // We already have DeployRaffle to perform procedure from Create Subscription to Add Consumer, on Real live chains (Test/Main).
        if (block.chainid != 31337) return;
        _;
    }

    function testCreateSubscriptionExecutesAsIntendedAndGivesASubscriptionId() public skipTest {
        CreateSubscription createSubscription = new CreateSubscription();
        uint64 actualSubscriptionId = createSubscription.createSubscription(s_vrfCoordinatorV2Address, s_privateKey);

        assert(actualSubscriptionId != s_subId);
        assert(actualSubscriptionId != 0);
    }

    function testFundSubscriptionExecutesAsIntendedAndFundsToKeepersWithGivenSubscriptionId() public skipTest {
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address);
        (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) =
            vrfCoordinator.getSubscription(s_subId);

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(s_vrfCoordinatorV2Address, s_linkTokenAddress, s_subId, s_privateKey);

        (uint96 updatedBalance, uint64 updatedReqCount, address updatedOwner, address[] memory updatedConsumers) =
            vrfCoordinator.getSubscription(s_subId);

        assert(updatedBalance > balance);
        assertEq(updatedReqCount, reqCount);
        assertEq(updatedOwner, owner);
        assertEq(updatedConsumers.length, consumers.length);

        for (uint256 i = 0; i < consumers.length; i++) {
            assertEq(updatedConsumers[i], consumers[i]);
        }
    }

    function testAddConsumerExecutesAsIntendedAndAddsAConsumerIntoSubscriptionWithAssociatedId() public skipTest {
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(s_vrfCoordinatorV2Address);
        (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) =
            vrfCoordinator.getSubscription(s_subId);

        // Always adds a new consumer, If consumer already exists into consumers list then vrf simply ignores it.
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(3), s_vrfCoordinatorV2Address, s_subId, s_privateKey);

        (uint96 updatedBalance, uint64 updatedReqCount, address updatedOwner, address[] memory updatedConsumers) =
            vrfCoordinator.getSubscription(s_subId);

        assertEq(updatedBalance, balance);
        assertEq(updatedReqCount, reqCount);
        assertEq(updatedOwner, owner);
        assert(updatedConsumers.length > consumers.length);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig config;

    function setUp() external {
        config = new HelperConfig();
    }

    function testAnvilNetworkConfigs() public {
        HelperConfig newConfig = new HelperConfig();
        (
            address expectedVrfCoordinatorV2Address,
            uint256 expectedEntranceFee,
            bytes32 expectedGasLane,
            uint64 expectedSubId,
            uint32 expectedCallbackGasLimit,
            uint256 expectedInterval,
            uint256 expectedPrivateKey,
            address expectedLinkTokenAddress
        ) = newConfig.activeNetworkConfig();

        HelperConfig.NetworkConfig memory actualAnvilConfig = config.createOrGetAnvilNetworkConfig();

        assert(actualAnvilConfig.vrfCoordinatorV2Address != expectedVrfCoordinatorV2Address);
        assertEq(actualAnvilConfig.entranceFee, expectedEntranceFee);
        assertEq(actualAnvilConfig.gasLane, expectedGasLane);
        assertEq(actualAnvilConfig.subId, expectedSubId);
        assertEq(actualAnvilConfig.callbackGasLimit, expectedCallbackGasLimit);
        assertEq(actualAnvilConfig.interval, expectedInterval);
        assertEq(actualAnvilConfig.privateKey, expectedPrivateKey);
        assert(actualAnvilConfig.linkTokenAddress != expectedLinkTokenAddress);
    }

    function testGoerliNetworkConfigs() public {
        HelperConfig.NetworkConfig memory actualGoerliConfig = config.getGoerliNetworkConfig();

        assertEq(actualGoerliConfig.vrfCoordinatorV2Address, 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        assertEq(actualGoerliConfig.entranceFee, 0.001 ether);
        assertEq(actualGoerliConfig.gasLane, 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15);
        assertEq(actualGoerliConfig.subId, 7569);
        assertEq(actualGoerliConfig.callbackGasLimit, 5000000);
        assertEq(actualGoerliConfig.interval, 30);
        assertEq(actualGoerliConfig.privateKey, vm.envUint("PRIVATE_KEY"));
        assertEq(actualGoerliConfig.linkTokenAddress, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    }

    function testSepoliaNetworkConfigs() public {
        HelperConfig.NetworkConfig memory actualSepoliaConfig = config.getSepoliaNetworkConfig();

        assertEq(actualSepoliaConfig.vrfCoordinatorV2Address, 0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        assertEq(actualSepoliaConfig.entranceFee, 0.001 ether);
        assertEq(actualSepoliaConfig.gasLane, 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c);
        assertEq(actualSepoliaConfig.subId, 7569);
        assertEq(actualSepoliaConfig.callbackGasLimit, 5000000);
        assertEq(actualSepoliaConfig.interval, 30);
        assertEq(actualSepoliaConfig.privateKey, vm.envUint("PRIVATE_KEY"));
        assertEq(actualSepoliaConfig.linkTokenAddress, 0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    function testMainnetNetworkConfigs() public {
        HelperConfig.NetworkConfig memory actualMainnetConfig = config.getMainnetNetworkConfig();

        assertEq(actualMainnetConfig.vrfCoordinatorV2Address, 0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        assertEq(actualMainnetConfig.entranceFee, 0.001 ether);
        assertEq(actualMainnetConfig.gasLane, 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef);
        assertEq(actualMainnetConfig.subId, 7569);
        assertEq(actualMainnetConfig.callbackGasLimit, 5000000);
        assertEq(actualMainnetConfig.interval, 30);
        assertEq(actualMainnetConfig.privateKey, vm.envUint("PRIVATE_KEY"));
        assertEq(actualMainnetConfig.linkTokenAddress, 0x514910771AF9Ca656af840dff83E8264EcF986CA);
    }
}

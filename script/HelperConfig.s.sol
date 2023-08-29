// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.m.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinatorV2Address;
        uint256 entranceFee;
        bytes32 gasLane;
        uint64 subId;
        uint32 callbackGasLimit;
        uint256 interval;
        uint256 privateKey;
        address linkTokenAddress;
    }

    NetworkConfig public activeNetworkConfig;

    uint256 private constant ENTRANCE_FEE = 0.001 ether;
    uint96 private constant BASE_FEE = 0.25 ether;
    uint96 private constant GAS_PRICE_LINK = 1e9;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaNetworkConfig();
        } else if (block.chainid == 5) {
            activeNetworkConfig = getGoerliNetworkConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetNetworkConfig();
        } else {
            activeNetworkConfig = createOrGetAnvilNetworkConfig();
        }
    }

    function getSepoliaNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorV2Address: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            entranceFee: ENTRANCE_FEE,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId: 7569,
            callbackGasLimit: 5000000,
            interval: 30,
            privateKey: vm.envUint("PRIVATE_KEY"),
            linkTokenAddress: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getGoerliNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorV2Address: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D,
            entranceFee: ENTRANCE_FEE,
            gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            subId: 7569,
            callbackGasLimit: 5000000,
            interval: 30,
            privateKey: vm.envUint("PRIVATE_KEY"),
            linkTokenAddress: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        });
    }

    function getMainnetNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorV2Address: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            entranceFee: ENTRANCE_FEE,
            gasLane: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
            subId: 7569,
            callbackGasLimit: 5000000,
            interval: 30,
            privateKey: vm.envUint("PRIVATE_KEY"),
            linkTokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA
        });
    }

    function createOrGetAnvilNetworkConfig() public returns (NetworkConfig memory) {
        bool isTrue = activeNetworkConfig.vrfCoordinatorV2Address != address(0);
        if (isTrue) {
            return activeNetworkConfig;
        }

        uint256 ANVIL_PRIVATE_KEY = vm.envUint("ANVIL_PRIVATE_KEY");

        vm.startBroadcast(ANVIL_PRIVATE_KEY);
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            vrfCoordinatorV2Address: address(vrfCoordinatorV2Mock),
            entranceFee: ENTRANCE_FEE,
            gasLane: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
            subId: 0,
            callbackGasLimit: 5000000,
            interval: 30,
            privateKey: ANVIL_PRIVATE_KEY,
            linkTokenAddress: address(linkToken)
        });
    }
}

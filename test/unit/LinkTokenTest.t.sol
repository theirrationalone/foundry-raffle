// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {LinkToken} from "../mocks/LinkToken.m.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract LinkTokenTest is Test {
    LinkToken linkToken;
    address private s_vrfCoordinatorV2Address;
    uint64 private s_subId;

    function setUp() external {
        HelperConfig config;
        DeployRaffle deployer = new DeployRaffle();
        (, config, s_subId) = deployer.run();
        (s_vrfCoordinatorV2Address,,,,,,,) = config.activeNetworkConfig();
        linkToken = new LinkToken();
    }

    function testTransferAndCallRevertsOnLocalChain() public {
        vm.expectRevert();
        bool success = linkToken.transferAndCall(s_vrfCoordinatorV2Address, 3 ether, abi.encode(s_subId));
        assertEq(success, false);
    }
}

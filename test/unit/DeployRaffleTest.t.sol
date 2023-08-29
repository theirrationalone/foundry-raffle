// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DeployRaffleTest is Test {
    DeployRaffle deployer;

    function setUp() external {
        deployer = new DeployRaffle();
    }

    function testDeployRaffleScriptWorksCorrectly() public {
        (Raffle raffle, HelperConfig config, uint64 subId) = deployer.run();

        assert(address(deployer) != address(0));
        assert(address(raffle) != address(0));
        assert(address(config) != address(0));
        assert(subId != 0);
    }
}

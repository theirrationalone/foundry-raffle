// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
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
        (raffle, config,) = deployer.run();

        RaffleHandler handler = new RaffleHandler(address(raffle));

        targetContract(address(handler));
    }
}

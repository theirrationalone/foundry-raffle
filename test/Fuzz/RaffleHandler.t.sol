// SPDX-License-Identifer: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

import {Raffle} from "../../src/Raffle.sol";

contract RaffleHandler is Test {
    Raffle private immutable i_raffle;

    constructor(address _raffleAddress) {
        i_raffle = Raffle(_raffleAddress);
    }
}

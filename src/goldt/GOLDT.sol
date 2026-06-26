// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {GoldTokenBase} from "../core/GoldTokenBase.sol";

contract GOLDT is GoldTokenBase {
    constructor(
        address oracle_,
        address vault_,
        address creator_,
        address feeRecipient_
    )
        GoldTokenBase(
            "GOLD Token",
            "GOLDT",
            6,
            oracle_,
            vault_,
            creator_,
            keccak256("XAU/DAI"),
            100,
            10000 * 1e6,
            0.001 ether,
            100 ether,
            feeRecipient_
        )
    {}
}

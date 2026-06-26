// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {GoldTokenBase} from "../core/GoldTokenBase.sol";

contract FIAT_G is GoldTokenBase {
    constructor(
        address oracle_,
        address vault_,
        address creator_,
        address feeRecipient_
    )
        GoldTokenBase(
            "Fiat Gold",
            "FIAT_G",
            6,
            oracle_,
            vault_,
            creator_,
            keccak256("BNB/DAI"),
            100,
            100000 * 1e6,
            0.001 ether,
            1000 ether,
            feeRecipient_
        )
    {}
}

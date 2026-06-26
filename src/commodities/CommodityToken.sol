// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {GoldTokenBase} from "../core/GoldTokenBase.sol";

contract CommodityToken is GoldTokenBase {
    constructor(
        string memory name_,
        string memory symbol_,
        address oracle_,
        address vault_,
        address creator_,
        bytes32 pricePair_,
        uint256 feeBps_,
        uint256 maxWallet__,
        uint256 minDeposit__,
        uint256 maxDeposit__,
        address feeRecipient_
    )
        GoldTokenBase(
            name_,
            symbol_,
            6,
            oracle_,
            vault_,
            creator_,
            pricePair_,
            feeBps_,
            maxWallet__,
            minDeposit__,
            maxDeposit__,
            feeRecipient_
        )
    {}
}

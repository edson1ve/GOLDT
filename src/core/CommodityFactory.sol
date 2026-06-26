// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CommodityToken} from "../commodities/CommodityToken.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract CommodityFactory {
    IOracle public oracle;
    address public vault;
    address public creator;
    address public feeRecipient;

    CommodityToken[] public tokens;
    mapping(bytes32 => address) public tokenByPair;

    event TokenCreated(
        address indexed token,
        string name,
        string symbol,
        bytes32 pair,
        uint256 index
    );

    constructor(address oracle_, address vault_, address creator_, address feeRecipient_) {
        oracle = IOracle(oracle_);
        vault = vault_;
        creator = creator_;
        feeRecipient = feeRecipient_;
    }

    function createToken(
        string calldata name,
        string calldata symbol,
        bytes32 pricePair,
        uint256 feeBps,
        uint256 maxWallet_,
        uint256 minDeposit_,
        uint256 maxDeposit_
    ) external returns (address) {
        require(tokenByPair[pricePair] == address(0), "Pair already registered");
        require(_msgSender() == creator, "Only creator");

        CommodityToken token = new CommodityToken(
            name, symbol,
            address(oracle), vault, creator,
            pricePair, feeBps,
            maxWallet_, minDeposit_, maxDeposit_,
            feeRecipient
        );

        tokens.push(token);
        tokenByPair[pricePair] = address(token);

        emit TokenCreated(address(token), name, symbol, pricePair, tokens.length - 1);
        return address(token);
    }

    function setFeeRecipient(address feeRecipient_) external {
        require(_msgSender() == creator, "Only creator");
        feeRecipient = feeRecipient_;
    }

    function getTokens() external view returns (CommodityToken[] memory) {
        return tokens;
    }

    function tokenCount() external view returns (uint256) {
        return tokens.length;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CommodityToken} from "../commodities/CommodityToken.sol";

contract FIAT_G_Factory {
    address public oracle;
    address public vault;
    address public creator;
    address public feeRecipient;

    mapping(string => address) public tokenByIso;
    address[] public tokens;

    event FIAT_GDeployed(string indexed iso, address indexed token, string name);

    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator");
        _;
    }

    constructor(address oracle_, address vault_, address creator_, address feeRecipient_) {
        oracle = oracle_;
        vault = vault_;
        creator = creator_;
        feeRecipient = feeRecipient_;
    }

    function deploy(string calldata iso, string calldata name, bytes32 pricePair) external onlyCreator returns (address) {
        require(tokenByIso[iso] == address(0), "Already deployed");
        require(bytes(iso).length > 0, "Empty ISO");

        CommodityToken token = new CommodityToken(
            name,
            string.concat("FIAT_G_", iso),
            oracle,
            vault,
            creator,
            pricePair,
            100,
            100000 * 1e6,
            0.001 ether,
            1000 ether,
            feeRecipient
        );

        tokenByIso[iso] = address(token);
        tokens.push(address(token));
        emit FIAT_GDeployed(iso, address(token), name);
        return address(token);
    }

    function tokenCount() external view returns (uint256) {
        return tokens.length;
    }

    function getAllTokens() external view returns (address[] memory) {
        return tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract Oracle is IOracle, Ownable {
    uint256 public constant ONE_DAY = 24 hours;
    mapping(bytes32 => PriceRecord) public prices;
    mapping(address => bool) public updaters;

    event PriceUpdated(bytes32 indexed pair, uint256 price, uint256 day);
    event UpdaterSet(address indexed updater, bool active);

    modifier onlyUpdater() {
        require(updaters[_msgSender()] || _msgSender() == owner(), "Not updater");
        _;
    }

    constructor() Ownable(_msgSender()) {}

    function setUpdater(address updater, bool active) external onlyOwner {
        updaters[updater] = active;
        emit UpdaterSet(updater, active);
    }

    function updatePrice(bytes32 pair, uint256 price) external onlyUpdater {
        uint256 day = block.timestamp / ONE_DAY;
        prices[pair] = PriceRecord(price, block.timestamp, day);
        emit PriceUpdated(pair, price, day);
    }

    function getPrice(bytes32 pair) external view returns (PriceRecord memory) {
        return prices[pair];
    }

    function isPriceValid(bytes32 pair) public view returns (bool) {
        PriceRecord memory r = prices[pair];
        if (r.timestamp == 0) return false;
        uint256 currentDay = block.timestamp / ONE_DAY;
        return r.day == currentDay;
    }

    function getDay() external view returns (uint256) {
        return block.timestamp / ONE_DAY;
    }

    function requirePrice(bytes32 pair) external view {
        require(isPriceValid(pair), "Oracle: price not updated today");
    }
}

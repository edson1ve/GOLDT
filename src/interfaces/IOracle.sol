// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IOracle {
    struct PriceRecord {
        uint256 price;
        uint256 timestamp;
        uint256 day;
    }

    function updatePrice(bytes32 pair, uint256 price) external;
    function getPrice(bytes32 pair) external view returns (PriceRecord memory);
    function isPriceValid(bytes32 pair) external view returns (bool);
    function requirePrice(bytes32 pair) external view;
    function getDay() external view returns (uint256);
}

interface IVault {
    function deposit() external payable;
    function totalValue() external view returns (uint256);
}

interface IGoldToken {
    function convert(uint256 amount, bytes32 pair) external payable returns (uint256 orderId);
    function batchMint(address[] calldata to, uint256[] calldata amounts) external;
    function maxWallet() external view returns (uint256);
    function minDeposit() external view returns (uint256);
}

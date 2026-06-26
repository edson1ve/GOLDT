// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IOracle, IVault} from "../interfaces/IOracle.sol";

abstract contract GoldTokenBase is ERC20 {
    IOracle public oracle;
    IVault public vault;
    address public creator;
    bytes32 public pricePair;
    uint256 public feeBps;
    uint256 public maxWallet_;
    uint256 public minDepositWei;
    uint256 public maxDepositWei;
    uint256 public overrideDecimals_;
    address public feeRecipient;

    mapping(address => uint256) public totalDepositedWei;

    event ConversionRequested(
        address indexed user,
        uint256 amount,
        uint256 feeAmount,
        uint256 orderId
    );

    modifier onlyCreator() {
        require(_msgSender() == creator, "Only creator");
        _;
    }

    modifier priceValid() {
        oracle.requirePrice(pricePair);
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address oracle_,
        address vault_,
        address creator_,
        bytes32 pricePair_,
        uint256 feeBps_,
        uint256 maxWallet__,
        uint256 minDepositWei_,
        uint256 maxDepositWei_,
        address feeRecipient_
    ) ERC20(name_, symbol_) {
        oracle = IOracle(oracle_);
        vault = IVault(vault_);
        creator = creator_;
        pricePair = pricePair_;
        feeBps = feeBps_;
        maxWallet_ = maxWallet__;
        minDepositWei = minDepositWei_;
        maxDepositWei = maxDepositWei_;
        overrideDecimals_ = decimals_;
        feeRecipient = feeRecipient_;
    }

    function decimals() public view override returns (uint8) {
        return uint8(overrideDecimals_);
    }

    function convert(uint256 amount, bytes32 pair) external payable priceValid returns (uint256) {
        require(pair == pricePair, "Wrong pair");
        require(amount > 0, "Zero amount");
        require(balanceOf(_msgSender()) + amount <= maxWallet_, "Exceeds max wallet");

        uint256 newTotal = totalDepositedWei[_msgSender()] + msg.value;
        require(newTotal >= minDepositWei, "Min deposit not met");
        require(newTotal <= maxDepositWei, "Exceeds max deposit");

        totalDepositedWei[_msgSender()] = newTotal;

        uint256 feeAmount = (amount * feeBps) / 10000;

        // ponytail: 1% fixed fee in tokens, all BNB goes to vault
        (bool sent,) = address(vault).call{value: msg.value}("");
        require(sent, "Transfer to vault failed");

        _mint(_msgSender(), amount);
        if (feeAmount > 0) {
            _mint(feeRecipient, feeAmount);
        }

        emit ConversionRequested(_msgSender(), amount, feeAmount, 0);
        return 0;
    }

    function setFeeRecipient(address feeRecipient_) external onlyCreator {
        feeRecipient = feeRecipient_;
    }

    function batchMint(address[] calldata to, uint256[] calldata amounts) external onlyCreator {
        require(to.length == amounts.length, "Length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            require(to[i] != address(0), "Zero address");
            require(amounts[i] > 0, "Zero amount");
            require(balanceOf(to[i]) + amounts[i] <= maxWallet_, "Exceeds max wallet");

            uint256 feeAmount = (amounts[i] * feeBps) / 10000;
            _mint(to[i], amounts[i]);
            if (feeAmount > 0) {
                _mint(feeRecipient, feeAmount);
            }
        }
    }

    function maxWallet() external view returns (uint256) {
        return maxWallet_;
    }

    function minDeposit() external view returns (uint256) {
        return minDepositWei;
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);
        if (to != address(0) && to != creator && to != feeRecipient) {
            require(balanceOf(to) <= maxWallet_, "Max wallet exceeded");
        }
    }
}

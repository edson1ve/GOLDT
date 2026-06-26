// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GOLDVE is ERC20, Ownable {
    event GOLDVEMinted(address indexed to, uint256 amount);

    // ponytail: discretionary vault, creator mints manually for contributors
    constructor(address initialOwner) ERC20("Goldve Value Token", "GOLDVE") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit GOLDVEMinted(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    receive() external payable {}
}

contract Vault is Ownable {
    uint256 public vaultTotalValue;

    event ValueUpdated(uint256 totalValue);
    event Deposit(address indexed from, address indexed token, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function deposit() external payable {
        vaultTotalValue += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
        emit ValueUpdated(vaultTotalValue);
    }

    function requestMint(address token) external payable {
        require(msg.value > 0, "Zero BNB");
        vaultTotalValue += msg.value;
        emit Deposit(msg.sender, token, msg.value);
        emit ValueUpdated(vaultTotalValue);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(amount <= vaultTotalValue, "Insufficient");
        require(amount <= address(this).balance, "Insufficient balance");
        vaultTotalValue -= amount;
        (bool sent,) = to.call{value: amount, gas: 5000}("");
        require(sent, "Withdraw failed");
        emit Withdrawn(to, amount);
        emit ValueUpdated(vaultTotalValue);
    }

    function totalValue() external view returns (uint256) {
        return vaultTotalValue;
    }

    receive() external payable {
        vaultTotalValue += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
        emit ValueUpdated(vaultTotalValue);
    }
}

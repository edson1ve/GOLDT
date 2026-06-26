// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Oracle} from "../src/core/Oracle.sol";
import {Vault, GOLDVE} from "../src/vault/GOLDVE.sol";
import {GOLDT} from "../src/goldt/GOLDT.sol";
import {FIAT_G} from "../src/fiat_g/FIAT_G.sol";
import {CommodityFactory} from "../src/core/CommodityFactory.sol";
import {FIAT_G_Factory} from "../src/fiat_g/FIAT_G_Factory.sol";

contract DeployGOLDT is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        Oracle oracle = new Oracle();
        Vault vault = new Vault(deployer);
        GOLDVE goldve = new GOLDVE(deployer);

        GOLDT goldt = new GOLDT(address(oracle), address(vault), deployer, address(goldve));
        FIAT_G fiat_g = new FIAT_G(address(oracle), address(vault), deployer, address(goldve));

        CommodityFactory factory = new CommodityFactory(address(oracle), address(vault), deployer, address(goldve));
        FIAT_G_Factory fiatGFactory = new FIAT_G_Factory(address(oracle), address(vault), deployer, address(goldve));

        vm.stopBroadcast();

        console.log("Oracle:    ", address(oracle));
        console.log("Vault:     ", address(vault));
        console.log("GOLDVE:    ", address(goldve));
        console.log("GOLDT:     ", address(goldt));
        console.log("FIAT_G:    ", address(fiat_g));
        console.log("Factory:   ", address(factory));
        console.log("FIAT_G_Factory:", address(fiatGFactory));
    }
}

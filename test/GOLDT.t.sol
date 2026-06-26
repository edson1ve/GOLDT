// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Oracle} from "../src/core/Oracle.sol";
import {Vault, GOLDVE} from "../src/vault/GOLDVE.sol";
import {GOLDT} from "../src/goldt/GOLDT.sol";
import {FIAT_G} from "../src/fiat_g/FIAT_G.sol";
import {CommodityToken} from "../src/commodities/CommodityToken.sol";
import {CommodityFactory} from "../src/core/CommodityFactory.sol";
import {FIAT_G_Factory} from "../src/fiat_g/FIAT_G_Factory.sol";
import {GoldTokenBase} from "../src/core/GoldTokenBase.sol";
import {IOracle} from "../src/interfaces/IOracle.sol";

contract GOLDTTest is Test {
    Oracle public oracle;
    Vault public vault;
    GOLDVE public goldve;
    GOLDT public goldt;
    FIAT_G public fiat_g;
    CommodityFactory public factory;
    FIAT_G_Factory public fiatGFactory;

    address public creator = address(0x1);
    address public user = address(0x2);
    address public updater = address(0x3);
    bytes32 public constant XAU_DAI = keccak256("XAU/DAI");
    bytes32 public constant BNB_DAI = keccak256("BNB/DAI");
    bytes32 public constant MAIZ_DAI = keccak256("MAIZ/DAI");
    bytes32 public constant VES_USD = keccak256("VES/USD");

    function setUp() public {
        vm.startPrank(creator);
        oracle = new Oracle();
        vault = new Vault(creator);
        goldve = new GOLDVE(creator);
        goldt = new GOLDT(address(oracle), address(vault), creator, address(goldve));
        fiat_g = new FIAT_G(address(oracle), address(vault), creator, address(goldve));
        factory = new CommodityFactory(address(oracle), address(vault), creator, address(goldve));
        fiatGFactory = new FIAT_G_Factory(address(oracle), address(vault), creator, address(goldve));
        oracle.setUpdater(updater, true);
        vm.stopPrank();
    }

    // ─── Oracle Tests ───────────────────────────────────────

    function test_Oracle_UpdatePrice() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        IOracle.PriceRecord memory r = oracle.getPrice(XAU_DAI);
        assertEq(r.price, 2000 * 1e18);
        assertTrue(r.timestamp > 0);
        assertEq(r.day, block.timestamp / 24 hours);
    }

    function test_Oracle_PriceExpires() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        assertTrue(oracle.isPriceValid(XAU_DAI));

        vm.warp(block.timestamp + 25 hours);
        assertFalse(oracle.isPriceValid(XAU_DAI));
    }

    function test_Oracle_RevertWhenExpired() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        assertTrue(oracle.isPriceValid(XAU_DAI));

        vm.warp(block.timestamp + 25 hours);
        assertFalse(oracle.isPriceValid(XAU_DAI));

        vm.expectRevert("Oracle: price not updated today");
        oracle.requirePrice(XAU_DAI);
    }

    // ─── GOLDT Tests ────────────────────────────────────────

    function test_GOLDT_NameSymbolDecimals() public {
        assertEq(goldt.name(), "GOLD Token");
        assertEq(goldt.symbol(), "GOLDT");
        assertEq(goldt.decimals(), 6);
    }

    function test_GOLDT_Convert() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        vm.prank(updater);
        oracle.updatePrice(BNB_DAI, 600 * 1e18);

        vm.deal(user, 10 ether);
        vm.prank(user);
        goldt.convert{value: 1 ether}(100 * 1e6, XAU_DAI);
        assertEq(goldt.balanceOf(user), 100 * 1e6);
    }

    function test_GOLDT_MaxWallet() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        vm.deal(user, 1000 ether);
        vm.prank(user);
        vm.expectRevert();
        goldt.convert{value: 100 ether}(20000 * 1e6, XAU_DAI);
    }

    function test_GOLDT_FeeSentToVault() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        uint256 vaultBefore = address(vault).balance;
        vm.deal(user, 10 ether);
        vm.prank(user);
        goldt.convert{value: 1 ether}(100 * 1e6, XAU_DAI);

        assertEq(address(vault).balance - vaultBefore, 1 ether);
    }

    function test_GOLDT_FeeRecipientGetsTokens() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        vm.deal(user, 10 ether);
        vm.prank(user);
        goldt.convert{value: 1 ether}(100 * 1e6, XAU_DAI);

        // 1% fee = 1e6 (100 * 1e6 / 100)
        assertEq(goldt.balanceOf(address(goldve)), 1 * 1e6);
    }

    function test_GOLDT_RevertWhenOracleExpired() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        vm.warp(block.timestamp + 25 hours);

        vm.deal(user, 10 ether);
        vm.prank(user);
        vm.expectRevert("Oracle: price not updated today");
        goldt.convert{value: 1 ether}(100 * 1e6, XAU_DAI);
    }

    // ─── FIAT_G Tests ───────────────────────────────────────

    function test_FIAT_G_Convert() public {
        vm.prank(updater);
        oracle.updatePrice(BNB_DAI, 600 * 1e18);

        vm.deal(user, 10 ether);
        vm.prank(user);
        fiat_g.convert{value: 1 ether}(100 * 1e6, BNB_DAI);
        assertEq(fiat_g.balanceOf(user), 100 * 1e6);
    }

    function test_FIAT_G_InitialDepositLimit() public {
        vm.prank(updater);
        oracle.updatePrice(BNB_DAI, 600 * 1e18);

        vm.deal(user, 2000 ether);
        vm.prank(user);
        vm.expectRevert("Exceeds max deposit");
        fiat_g.convert{value: 1500 ether}(100000 * 1e6, BNB_DAI);
    }

    // ─── Vault + GOLDVE Tests ──────────────────────────────

    function test_Vault_ReceivesBNB() public {
        vm.deal(creator, 10 ether);
        vm.prank(creator);
        vault.deposit{value: 5 ether}();
        assertEq(vault.totalValue(), 5 ether);
    }

    function test_GOLDVE_Mint() public {
        vm.prank(creator);
        goldve.mint(user, 1000 * 1e18);
        assertEq(goldve.balanceOf(user), 1000 * 1e18);
    }

    function test_GOLDVE_Burn() public {
        vm.prank(creator);
        goldve.mint(user, 1000 * 1e18);
        vm.prank(creator);
        goldve.burn(user, 400 * 1e18);
        assertEq(goldve.balanceOf(user), 600 * 1e18);
    }

    function test_GOLDVE_NonOwnerCannotMint() public {
        vm.prank(user);
        vm.expectRevert();
        goldve.mint(user, 100 * 1e18);
    }

    function test_GOLDVE_FeeFromConversion() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        vm.deal(user, 10 ether);
        vm.prank(user);
        goldt.convert{value: 1 ether}(100 * 1e6, XAU_DAI);

        // 1% of 100 tokens = 1 token sent to GOLDVE as fee
        assertEq(goldt.balanceOf(address(goldve)), 1 * 1e6);
    }

    // ─── Factory Tests ─────────────────────────────────────

    function test_Factory_CreateCommodity() public {
        vm.prank(updater);
        oracle.updatePrice(MAIZ_DAI, 200 * 1e18);

        vm.prank(creator);
        address token = factory.createToken(
            "Maiz G", "MAIZ_G",
            MAIZ_DAI, 10,
            100000 * 1e6,
            500 * 1e6,
            100000 * 1e6
        );

        assertTrue(token != address(0));
        assertEq(factory.tokenCount(), 1);
        assertEq(factory.tokenByPair(MAIZ_DAI), token);
    }

    function test_Factory_PreventsDuplicatePair() public {
        vm.prank(creator);
        factory.createToken(
            "Maiz G", "MAIZ_G",
            MAIZ_DAI, 10,
            100000 * 1e6,
            500 * 1e6,
            100000 * 1e6
        );

        vm.prank(creator);
        vm.expectRevert();
        factory.createToken(
            "Maiz2 G", "MAI2_G",
            MAIZ_DAI, 10,
            100000 * 1e6,
            500 * 1e6,
            100000 * 1e6
        );
    }

    // ─── Transfer Tests ─────────────────────────────────────

    function test_Transfer_EnforcesMaxWallet() public {
        vm.prank(updater);
        oracle.updatePrice(XAU_DAI, 2000 * 1e18);

        vm.deal(user, 10 ether);
        vm.prank(user);
        goldt.convert{value: 1 ether}(100 * 1e6, XAU_DAI);

        address user2 = address(0x4);
        vm.deal(user2, 10 ether);
        vm.prank(user2);
        goldt.convert{value: 1 ether}(100 * 1e6, XAU_DAI);

        vm.prank(user);
        vm.expectRevert();
        goldt.transfer(user2, 9900 * 1e6);
    }

    // ─── BatchMint Tests ────────────────────────────────────

    function test_BatchMint_Single() public {
        address[] memory to = new address[](1);
        to[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 1e6;

        vm.prank(creator);
        goldt.batchMint(to, amounts);

        assertEq(goldt.balanceOf(user), 100 * 1e6);
    }

    function test_BatchMint_Multiple() public {
        address userA = address(0xA);
        address userB = address(0xB);

        address[] memory to = new address[](2);
        to[0] = userA;
        to[1] = userB;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 * 1e6;
        amounts[1] = 70 * 1e6;

        vm.prank(creator);
        goldt.batchMint(to, amounts);

        assertEq(goldt.balanceOf(userA), 50 * 1e6);
        assertEq(goldt.balanceOf(userB), 70 * 1e6);
    }

    function test_BatchMint_FeeToGOLDVE() public {
        address userA = address(0xA);
        address userB = address(0xB);

        address[] memory to = new address[](2);
        to[0] = userA;
        to[1] = userB;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 * 1e6;
        amounts[1] = 200 * 1e6;

        vm.prank(creator);
        goldt.batchMint(to, amounts);

        // 1% fee: 300 * 1e6 / 100 = 3e6
        assertEq(goldt.balanceOf(address(goldve)), 3 * 1e6);
    }

    function test_BatchMint_NonCreatorReverts() public {
        address[] memory to = new address[](1);
        to[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 1e6;

        vm.prank(user);
        vm.expectRevert("Only creator");
        goldt.batchMint(to, amounts);
    }

    function test_BatchMint_LengthMismatchReverts() public {
        address[] memory to = new address[](1);
        to[0] = user;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 * 1e6;
        amounts[1] = 50 * 1e6;

        vm.prank(creator);
        vm.expectRevert("Length mismatch");
        goldt.batchMint(to, amounts);
    }

    function test_BatchMint_ExceedsMaxWalletReverts() public {
        address[] memory to = new address[](1);
        to[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 20000 * 1e6;

        vm.prank(creator);
        vm.expectRevert("Exceeds max wallet");
        goldt.batchMint(to, amounts);
    }

    // ─── Vault RequestMint Tests ────────────────────────────

    function test_Vault_RequestMint() public {
        vm.deal(user, 5 ether);
        vm.prank(user);
        vault.requestMint{value: 2 ether}(address(goldt));
        assertEq(vault.totalValue(), 2 ether);
    }

    function test_Vault_RequestMintZeroReverts() public {
        vm.prank(user);
        vm.expectRevert("Zero BNB");
        vault.requestMint{value: 0}(address(goldt));
    }

    function test_Vault_Withdraw() public {
        vm.deal(creator, 5 ether);
        assertEq(creator.balance, 5 ether);
        assertEq(address(vault).balance, 0);

        vm.prank(creator);
        vault.deposit{value: 3 ether}();

        assertEq(address(vault).balance, 3 ether);
        assertEq(vault.totalValue(), 3 ether);
        assertEq(creator.balance, 2 ether);

        address beneficiary = address(0x100);
        vm.prank(creator);
        vault.withdraw(beneficiary, 2 ether);

        assertEq(vault.totalValue(), 1 ether);
        assertEq(address(vault).balance, 1 ether);
        assertEq(beneficiary.balance, 2 ether);
    }

    function test_Vault_WithdrawInsufficientReverts() public {
        vm.deal(creator, 1 ether);
        vm.prank(creator);
        vault.deposit{value: 1 ether}();

        vm.prank(creator);
        vm.expectRevert("Insufficient");
        vault.withdraw(address(0x100), 2 ether);
    }

    function test_Vault_NonOwnerCannotWithdraw() public {
        vm.deal(creator, 5 ether);
        vm.prank(creator);
        vault.deposit{value: 3 ether}();

        vm.prank(user);
        vm.expectRevert();
        vault.withdraw(user, 1 ether);
    }

    // ─── FIAT_G_Factory Tests ───────────────────────────────

    function test_FIAT_G_Factory_Deploy() public {
        vm.prank(creator);
        address token = fiatGFactory.deploy("VES", "GOLDVE Venezuelan Bolivar", VES_USD);

        assertTrue(token != address(0));
        assertEq(fiatGFactory.tokenCount(), 1);
        assertEq(fiatGFactory.tokenByIso("VES"), token);
    }

    function test_FIAT_G_Factory_PreventsDuplicate() public {
        vm.prank(creator);
        fiatGFactory.deploy("VES", "GOLDVE Venezuelan Bolivar", VES_USD);

        vm.prank(creator);
        vm.expectRevert("Already deployed");
        fiatGFactory.deploy("VES", "GOLDVE VES Duplicate", VES_USD);
    }

    function test_FIAT_G_Factory_NonCreatorReverts() public {
        vm.prank(user);
        vm.expectRevert("Only creator");
        fiatGFactory.deploy("VES", "GOLDVE Venezuelan Bolivar", VES_USD);
    }

    function test_FIAT_G_Factory_MultipleDeployments() public {
        vm.prank(creator);
        address ves = fiatGFactory.deploy("VES", "GOLDVE Venezuelan Bolivar", VES_USD);

        bytes32 brlUsd = keccak256("BRL/USD");
        vm.prank(creator);
        address brl = fiatGFactory.deploy("BRL", "GOLDVE Brazilian Real", brlUsd);

        assertEq(fiatGFactory.tokenCount(), 2);
        assertTrue(ves != brl);
    }
}

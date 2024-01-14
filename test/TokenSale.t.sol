//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {TokenSale} from "../src/TokenSale.sol";
import {ERC20Token} from "../src/ERC20Token.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TokenSaleTest is Test {
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    TokenSale public tokenSaleContract;

    error Sale_PresaleNotStarted();

    uint256 public constant SALE_START_DURATION = 86400; // 1 day
    uint256 public constant PRESALE_DURATION = 86400; // 1 day
    uint256 public constant PUBLIC_SALE_DURATION = 259200; // 3 days

    function setUp() public {
        vm.prank(owner);
        tokenSaleContract = new TokenSale();

        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
    }

    modifier createSale() {
        vm.prank(owner);
        tokenSaleContract.createSale(
            "Supra",
            "SUPRA",
            10 ether, // presale max cap
            1 ether, // min contrib
            5 ether, // max contrib
            30 ether, // public max cap
            1 ether, // min contrib
            10 ether // max contrib
        );
        _;
    }

    function test_CreateSale() public {
        vm.prank(owner);
        tokenSaleContract.createSale(
            "Supra",
            "SUPRA",
            10 ether, // presale max cap
            1 ether, // min contrib
            5 ether, // max contrib
            30 ether, // public max cap
            1 ether, // min contrib
            10 ether // max contrib
        );

        assertEq(tokenSaleContract.getSaleId("SUPRA"), 1);

        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);

        assertEq(ERC20Token(sale.token).name(), "Supra");
        assertEq(ERC20Token(sale.token).symbol(), "SUPRA");
        assertEq(sale.presaleMaxCap, 10 ether);
        assertEq(sale.presaleMinContribution, 1 ether);
        assertEq(sale.presaleMaxContribution, 5 ether);
        assertEq(sale.presaleContributions, 0 ether);
        assertEq(sale.publicMaxCap, 30 ether);
        assertEq(sale.publicMinContribution, 1 ether);
        assertEq(sale.publicMaxContribution, 10 ether);
        assertEq(sale.publicContributions, 0 ether);
    }

    function test_user_createSale() public {
        vm.startPrank(user1);
        // vm.expectRevert(tokenSaleContract.OwnableUnauthorizedAccount.selector, 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF);
        vm.expectRevert();
        tokenSaleContract.createSale(
            "Supra",
            "SUPRA",
            10 ether, // presale max cap
            1 ether, // min contrib
            5 ether, // max contrib
            30 ether, // public max cap
            1 ether, // min contrib
            10 ether // max contrib
        );
        vm.stopPrank();
    }

    function test_contributeToPresale() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + 1);

        vm.startPrank(user1);
        tokenSaleContract.contributeToPresale{value: 1 ether}(1);
        vm.stopPrank();

        sale = tokenSaleContract.getSaleById(1);
        assertEq(sale.presaleContributions, 1 ether);
        assertEq(tokenSaleContract.getUserContributions(user1, 1), 1 ether);
    }

    function test_contributeToPresale_beforePresale() public createSale {
        vm.startPrank(user1);
        // vm.expectRevert(abi.encodeWithSelector(Sale_PresaleNotStarted.selector));
        vm.expectRevert();
        tokenSaleContract.contributeToPresale{value: 1 ether}(1);
        vm.stopPrank();
    }

    function test_contributeToPresale_afterPresaleEnded() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + 1 hours);

        vm.startPrank(user1);
        vm.expectRevert();
        tokenSaleContract.contributeToPresale{value: 1 ether}(1);
        vm.stopPrank();
    }

    function test_contributeToPresale_afterPublicEnded() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + PUBLIC_SALE_DURATION + 1 hours);

        vm.startPrank(user1);
        vm.expectRevert();
        tokenSaleContract.contributeToPresale{value: 1 ether}(1);
        vm.stopPrank();
    }

    function test_contributeToPublicSale_success() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + 1);

        vm.startPrank(user1);
        tokenSaleContract.contributeToPublicSale{value: 1 ether}(1);
        vm.stopPrank();

        sale = tokenSaleContract.getSaleById(1);
        assertEq(sale.publicContributions, 1 ether);
        assertEq(tokenSaleContract.getUserContributions(user1, 1), 1 ether);
    }

    function test_contributeToPublicSale_beforePublicSaleStarted() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + 1);

        vm.startPrank(user1);
        vm.expectRevert();
        tokenSaleContract.contributeToPublicSale{value: 1 ether}(1);
        vm.stopPrank();
    }

    function test_contributeToPublicSale_afterPublicSaleEnded() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + PUBLIC_SALE_DURATION + 1 hours);

        vm.startPrank(user1);
        vm.expectRevert();
        tokenSaleContract.contributeToPublicSale{value: 1 ether}(1);
        vm.stopPrank();
    }

    function test_presale_userReceiveTokens() public createSale {
        // participate in presale
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + 1);

        vm.startPrank(user1);
        tokenSaleContract.contributeToPresale{value: 1 ether}(1);
        vm.stopPrank();

        // verify tokens
        assertEq(ERC20Token(sale.token).balanceOf(user1), 1 ether);
    }

    function test_publicSale_userReceiveTokens() public createSale {
        // participate in public
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + 1);

        vm.startPrank(user1);
        tokenSaleContract.contributeToPublicSale{value: 1 ether}(1);
        vm.stopPrank();

        // verify tokens
        assertEq(ERC20Token(sale.token).balanceOf(user1), 1 ether);
    }

    function test_presaleMaxCap() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);

        // presale
        vm.warp(sale.startTime + SALE_START_DURATION + 1);
        uint256 prersale_amt = sale.presaleMaxContribution;
        for(uint256 i; i < 2; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, prersale_amt);

            vm.startPrank(userAddress);
            tokenSaleContract.contributeToPresale{value: prersale_amt}(1);
            vm.stopPrank();
        }
    }

    function testFail_presaleMaxcap() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);

        // presale
        vm.warp(sale.startTime + SALE_START_DURATION + 1);
        uint256 prersale_amt = sale.presaleMaxContribution;
        for(uint256 i; i < 3; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, prersale_amt);

            vm.startPrank(userAddress);
            tokenSaleContract.contributeToPresale{value: prersale_amt}(1);
            vm.stopPrank();
        }
    }

    function test_publicSaleMaxCap() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);

        // public sale
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + 1);
        uint256 publicSale_amt = sale.publicMaxContribution;
        for(uint256 i; i < 2; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, publicSale_amt);

            vm.startPrank(userAddress);
            tokenSaleContract.contributeToPublicSale{value: publicSale_amt}(1);
            vm.stopPrank();
        }
    }

    function testFail_publicSaleMaxcap() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);

        // public sale
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + 1);
        uint256 publicSale_amt = sale.publicMaxContribution;
        for(uint256 i; i < 4; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, publicSale_amt);

            vm.startPrank(userAddress);
            tokenSaleContract.contributeToPublicSale{value: publicSale_amt}(1);
            vm.stopPrank();
        }
    }

    function test_claimContribution() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        uint256 startTime = sale.startTime;

        // start pre-sale
        vm.warp(startTime + SALE_START_DURATION);

        // user 1 contribute
        vm.prank(user1);
        tokenSaleContract.contributeToPresale{value: 1 ether}(1);

        // end pre-sale
        vm.warp(block.timestamp + PRESALE_DURATION);

        // user 1 contribute
        vm.prank(user2);
        tokenSaleContract.contributeToPublicSale{value: 5 ether}(1);

        // end public-sale
        vm.warp(block.timestamp + PUBLIC_SALE_DURATION);

        assertEq(address(tokenSaleContract).balance, 6 ether);
        assertEq(tokenSaleContract.getUserContributions(user1, 1), 1 ether);
        assertEq(tokenSaleContract.getUserContributions(user2, 1), 5 ether);


        vm.startPrank(user1);
        ERC20Token(sale.token).approve(address(tokenSaleContract), type(uint).max);
        tokenSaleContract.claimContribution(1);
        assertEq(tokenSaleContract.getUserContributions(user1, 1), 0);
        vm.stopPrank();

        vm.startPrank(user2);
        ERC20Token(sale.token).approve(address(tokenSaleContract), type(uint).max);
        tokenSaleContract.claimContribution(1);
        assertEq(tokenSaleContract.getUserContributions(user2, 1), 0);
        vm.stopPrank();
    }

    function test_claimFailOnCapReached() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);

        // presale
        vm.warp(sale.startTime + SALE_START_DURATION + 1);
        uint256 prersale_amt = sale.presaleMaxContribution;
        for(uint256 i; i < 2; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, prersale_amt);

            vm.startPrank(userAddress);
            tokenSaleContract.contributeToPresale{value: prersale_amt}(1);
            vm.stopPrank();
        }

        // public sale
        vm.warp(block.timestamp + PRESALE_DURATION + 1);
        uint256 publicSale_amt = sale.publicMaxContribution;
        for(uint256 i=3; i < 6; i++) {
            string memory user = string(abi.encodePacked("user",  Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, publicSale_amt);

            vm.startPrank(userAddress);
            tokenSaleContract.contributeToPublicSale{value: publicSale_amt}(1);
            vm.stopPrank();
        }

        // end public sale
        vm.warp(block.timestamp + PUBLIC_SALE_DURATION + 1);

        sale = tokenSaleContract.getSaleById(1);
        assertEq(sale.publicMaxCap, sale.publicContributions);
        assertEq(sale.presaleMaxCap, sale.presaleContributions);

        vm.startPrank(user1);
        ERC20Token(sale.token).approve(address(tokenSaleContract), type(uint).max);
        assertEq(tokenSaleContract.getUserContributions(user1, 1),  5 ether);

        vm.expectRevert();
        tokenSaleContract.claimContribution(1);
        vm.stopPrank();
    }

    function test_ownerDistributeTokens() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        ERC20Token token = ERC20Token(sale.token);

        assertEq(token.balanceOf(user1), 0);

        vm.prank(owner);
        tokenSaleContract.distributeTokens(user1, 1, 10);

        assertEq(token.balanceOf(user1), 10);
    }

    function test_userCantDistributeTokens() public createSale {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(1);
        ERC20Token token = ERC20Token(sale.token);

        assertEq(token.balanceOf(user1), 0);

        vm.startPrank(user1);
        vm.expectRevert();
        tokenSaleContract.distributeTokens(user1, 1, 10);
    }
}
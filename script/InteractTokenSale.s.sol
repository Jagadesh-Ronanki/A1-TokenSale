// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TokenSale} from "../src/TokenSale.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DeployTokenSale} from "./DeployTokenSale.s.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

contract InteractTokenSale is Script {
    TokenSale public tokenSaleContract;
    HelperConfig public helperConfig;
    address[] public users;

    uint256 public constant SALE_START_DURATION = 86400; // 1 day
    uint256 public constant PRESALE_DURATION = 86400; // 1 day
    uint256 public constant PUBLIC_SALE_DURATION = 259200; // 3 days


    function run() public {
        DeployTokenSale deploy = new DeployTokenSale();
        (tokenSaleContract, helperConfig, users) = deploy.run();

        (,uint256 deployerKey) = helperConfig.activeNetworkConfig();

        console.log("============================");
        console.log("Scenario 1:");
        console.log("============================");

        uint256 saleId = createSale(deployerKey, "SupraOne", "SUPRAONE");
        scenarioOne(saleId);

        console.log("============================");
        console.log("Scenario 2:");
        console.log("============================");

        saleId = createSale(deployerKey, "SupraTwo", "SUPRATWO");
        scenarioTwo(saleId);
        console.log("============================");

    }

    function scenarioOne(uint256 saleId) public {
        contributeToPreSale(users[0], saleId, 1 ether);
        console.log("2. SUPRA Token presale contribution: ", tokenSaleContract.getSaleById(1).presaleContributions / 1e18, "ether");

        contributeToPublicSale(users[1], saleId, 3 ether);
        console.log("3. SUPRA Token public contribution: ", tokenSaleContract.getSaleById(1).publicContributions / 1e18, "ether");

        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(saleId);
        console.log("4. Sale Ended");
        console.log("5. Total contributions to sale:", (sale.presaleContributions + sale.publicContributions) / 1e18, "ether");

        claimTokens(users[0], saleId);
        console.log("6.", users[0], "claimed their contriburion");
        sale = tokenSaleContract.getSaleById(saleId);
        console.log("7. Total contributions to sale:", (sale.presaleContributions + sale.publicContributions) / 1e18, "ether");
    }

    function scenarioTwo(uint256 saleId) public {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(saleId);
        uint256 prersale_amt = sale.presaleMaxContribution;
        for(uint256 i; i < 2; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, prersale_amt);

            contributeToPreSale(userAddress, saleId, prersale_amt);
        }
        console.log("2. SUPRA Token presale contribution: ", tokenSaleContract.getSaleById(1).presaleContributions / 1e18, "ether");

        uint256 publicSale_amt = sale.publicMaxContribution;
        for(uint256 i=2; i < 11; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);
            vm.deal(userAddress, publicSale_amt);

            contributeToPublicSale(userAddress, saleId, publicSale_amt);
        }
        console.log("3. SUPRA Token public contribution: ", tokenSaleContract.getSaleById(1).publicContributions / 1e18, "ether");

        console.log("4. Sale Ended");
        console.log("5. User Contributions - SUPRA tokens minted");

        sale = tokenSaleContract.getSaleById(saleId);
        for(uint256 i; i < 3; i++) {
            string memory user = string(abi.encodePacked("user", Strings.toString(i)));
            address userAddress = makeAddr(user);

            uint256 userContribution = tokenSaleContract.getUserContributions(userAddress, saleId);
            uint256 supraBalance = ERC20Token(sale.token).balanceOf(userAddress);
            console.log(userContribution / 1e18, "ETH - ", supraBalance / 1e18, "SUPRA");
        }
    }

    function createSale(uint256 _deployerKey, string memory _name, string memory _symbol) public returns(uint256) {
        vm.startBroadcast(_deployerKey);

        tokenSaleContract.createSale(
            _name,
            _symbol,
            10 ether, // presale max cap
            1 ether, // min contrib
            5 ether, // max contrib
            30 ether, // public max cap
            1 ether, // min contrib
            3 ether // max contrib
        );

        vm.stopBroadcast();

        uint256 saleId = tokenSaleContract.getSaleId(_symbol);
        console.log("1. SUPRA Token sale created with id:", saleId);
        return saleId;
    }

    function contributeToPreSale(address _user, uint256 _saleId, uint256 _amount) public payable {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(_saleId);
        vm.warp(sale.startTime + SALE_START_DURATION + 1);
        vm.startBroadcast(_user);
        tokenSaleContract.contributeToPresale{value: _amount}(_saleId);
        vm.stopBroadcast();
    }

    function contributeToPublicSale(address _user, uint256 _saleId, uint256 _amount) public payable {
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(_saleId);
        vm.warp(sale.startTime + SALE_START_DURATION + PRESALE_DURATION + 1);
        vm.startBroadcast(_user);
        tokenSaleContract.contributeToPublicSale{value: _amount}(_saleId);
        vm.stopBroadcast();
    }

    function claimTokens(address _user, uint256 _saleId) public {
        vm.warp(block.timestamp + PUBLIC_SALE_DURATION);
        TokenSale.Sale memory sale = tokenSaleContract.getSaleById(_saleId);
        vm.startBroadcast(_user);
        ERC20Token(sale.token).approve(address(tokenSaleContract), type(uint).max);
        tokenSaleContract.claimContribution(1);
        vm.stopBroadcast();
    }


}
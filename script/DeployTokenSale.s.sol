// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {TokenSale} from "../src/TokenSale.sol";

contract DeployTokenSale is Script {
    address[] users;

    function run() external returns(TokenSale, HelperConfig, address[] memory) {
        HelperConfig helperConfig = new HelperConfig();
        (,uint256 deployerKey) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        TokenSale tokenSaleContract = new TokenSale();
        vm.stopBroadcast();

        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
        users.push(user1);
        users.push(user2);

        return (tokenSaleContract, helperConfig, users);
    }
}
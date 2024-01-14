//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

contract ERC20TokenTest is Test {
	ERC20Token private token;
	address public owner;
	address public user;

	function setUp() public {
		owner = makeAddr("owner");
		user = makeAddr("user");

		vm.prank(owner);
		token = new ERC20Token("Supra", "SUPRA");
	}

	modifier deployToken(string memory _name, string memory _symbol) {
		vm.prank(owner);
		token = new ERC20Token(_name, _symbol);
		_;
	}

	function testTokenName() public {
		assertEq(token.name(), "Supra");
	}

	function testTokenSymbol() public {
		assertEq(token.symbol(), "SUPRA");
	}

	function testOwnerCanMint() public {
		vm.prank(owner);
		token.mint(user, 10);

		assertEq(token.balanceOf(user), 10);
	}

	function testFailNonOwnerMint() public {
		vm.prank(user);
		token.mint(user, 10);
	}
}
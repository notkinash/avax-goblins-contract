// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/AvaxGoblins.sol";

contract AvaxGoblinsTest is Test {
    AvaxGoblins public avaxGoblins;

    function setUp() public {
        uint256 mintPrice = 0.1 ether;
        uint256 collectionSize = 100;
        address royaltiesReceiver = msg.sender;
        uint96 royaltiesFraction = 5 * 100;
        string memory metadataURI = "ipfs://";
        //
        avaxGoblins = new AvaxGoblins(mintPrice, collectionSize, royaltiesReceiver, royaltiesFraction, metadataURI);
        avaxGoblins.toggleMint();
    }

    // Whitelist Mint

    function testWhitelistMint1() public {
        vm.prank(avaxGoblins.owner());
        avaxGoblins.whitelistAdd(msg.sender);
        //
        uint256 quantity = 1;
        uint256 price = avaxGoblins.mintPrice() * quantity;
        //
        vm.prank(msg.sender);
        avaxGoblins.mint{value: price}(quantity);
        assertEq(avaxGoblins.balanceOf(msg.sender), quantity);
    }

    function testWhitelistMintMax() public {
        vm.prank(avaxGoblins.owner());
        avaxGoblins.whitelistAdd(msg.sender);
        //
        uint256 quantity = avaxGoblins.collectionSize();
        uint256 price = avaxGoblins.mintPrice() * quantity;
        //
        vm.prank(msg.sender);
        avaxGoblins.mint{value: price}(quantity);
        assertEq(avaxGoblins.balanceOf(msg.sender), quantity);
    }

    function testFailWhitelistMintMaxPlus1() public {
        vm.prank(avaxGoblins.owner());
        avaxGoblins.whitelistAdd(msg.sender);
        //
        uint256 quantity = avaxGoblins.collectionSize() + 1;
        uint256 price = avaxGoblins.mintPrice() * quantity;
        //
        vm.prank(msg.sender);
        avaxGoblins.mint{value: price}(quantity);
    }

    function testFailWhitelistMintWithoutWhitelist() public {
        uint256 quantity = 1;
        uint256 price = avaxGoblins.mintPrice() * quantity;
        //
        vm.prank(msg.sender);
        avaxGoblins.mint{value: price}(quantity);
    }

    // Public Mint

    function testPublicMint1() public {
        vm.prank(avaxGoblins.owner());
        avaxGoblins.togglePublicSale();
        //
        uint256 quantity = 1;
        uint256 price = avaxGoblins.mintPrice() * quantity;
        //
        vm.prank(msg.sender);
        avaxGoblins.mint{value: price}(quantity);
        assertEq(avaxGoblins.balanceOf(msg.sender), quantity);
    }

    function testPublicMintMax() public {
        vm.prank(avaxGoblins.owner());
        avaxGoblins.togglePublicSale();
        //
        uint256 quantity = avaxGoblins.collectionSize();
        uint256 price = avaxGoblins.mintPrice() * quantity;
        //
        vm.prank(msg.sender);
        avaxGoblins.mint{value: price}(quantity);
        assertEq(avaxGoblins.balanceOf(msg.sender), quantity);
    }

    function testFailPublicMintMaxPlus1() public {
        vm.prank(avaxGoblins.owner());
        avaxGoblins.togglePublicSale();
        //
        uint256 quantity = avaxGoblins.collectionSize() + 1;
        uint256 price = avaxGoblins.mintPrice() * quantity;
        //
        vm.prank(msg.sender);
        avaxGoblins.mint{value: price}(quantity);
    }

    // Whitelist Tests

    function testWhitelistAdd() public {
        vm.prank(avaxGoblins.owner());
        avaxGoblins.whitelistAdd(msg.sender);
        assertEq(avaxGoblins.whitelisted(msg.sender), true);
    }

    function testWhitelistRemove() public {
        testWhitelistAdd();
        vm.prank(avaxGoblins.owner());
        avaxGoblins.whitelistRemove(msg.sender);
        assertEq(avaxGoblins.whitelisted(msg.sender), false);
    }

    function testWhitelistMulti() public {
        address[] memory addresses = new address[](50);
        for (uint160 i = 0; i < 50; i++) {
            addresses[i] = address(0xfcfd + i);
        }
        vm.prank(avaxGoblins.owner());
        avaxGoblins.whitelistMulti(addresses);
        assertEq(avaxGoblins.whitelisted(addresses[49]), true);
    }

    // Royalties

    function testRoyalties() public {
        address owner = avaxGoblins.owner();
        // Setting royalties percentage
        uint96 percentage = 10;
        vm.prank(owner);
        avaxGoblins.setRoyaltiesFraction(percentage * 100);
        // Setting royalties receiver
        vm.prank(owner);
        avaxGoblins.setRoyaltiesReceiver(owner);
        // Testing the royalties
        uint256 salePrice = 1 ether;
        (address receiver, uint256 royaltyAmount) = avaxGoblins.royaltyInfo(0, salePrice);
        // Checks
        assertEq(receiver, owner);
        assertEq(royaltyAmount, salePrice / percentage);
    }
}
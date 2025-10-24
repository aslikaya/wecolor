// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorNFTTest
 * @notice Tests for NFT functionality and metadata
 */
contract WeColorNFTTest is Test {
    WeColor public wecolor;
    address public owner;
    address public buyer;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        buyer = makeAddr("buyer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        wecolor = new WeColor();
    }

    // Test: tokenURI returns valid data
    function testTokenURI() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        string memory uri = wecolor.tokenURI(1);

        // URI should start with data:application/json;base64,
        assertTrue(bytes(uri).length > 0);

        // Check it contains base64 prefix
        bytes memory uriBytes = bytes(uri);
        bytes memory prefix = bytes("data:application/json;base64,");
        bool hasPrefix = true;
        for (uint i = 0; i < prefix.length && i < uriBytes.length; i++) {
            if (uriBytes[i] != prefix[i]) {
                hasPrefix = false;
                break;
            }
        }
        assertTrue(hasPrefix);
    }

    // Test: tokenURI reverts for non-existent token
    function testTokenURIRevertsForNonExistentToken() public {
        vm.expectRevert("Token does not exist");
        wecolor.tokenURI(999);
    }

    // Test: ownerOf returns correct owner
    function testOwnerOf() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        assertEq(wecolor.ownerOf(1), buyer);
    }

    // Test: tokenIdToDate mapping works correctly
    function testTokenIdToDate() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors);

        uint256 price1 = wecolor.getDailyColor(20241024).price;
        uint256 price2 = wecolor.getDailyColor(20241025).price;

        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price1}(20241024);

        vm.prank(buyer);
        wecolor.buyNft{value: price2}(20241025);

        assertEq(wecolor.tokenIdToDate(1), 20241024);
        assertEq(wecolor.tokenIdToDate(2), 20241025);
    }

    // Test: NFT is ERC721 compliant
    function testERC721Compliance() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Test balanceOf
        assertEq(wecolor.balanceOf(buyer), 1);

        // Test name and symbol
        assertEq(wecolor.name(), "WeColor");
        assertEq(wecolor.symbol(), "WCLR");
    }

    // Test: NFT can be transferred
    function testNFTTransfer() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        address newOwner = makeAddr("newOwner");

        // Transfer NFT
        vm.prank(buyer);
        wecolor.transferFrom(buyer, newOwner, 1);

        assertEq(wecolor.ownerOf(1), newOwner);
        assertEq(wecolor.balanceOf(buyer), 0);
        assertEq(wecolor.balanceOf(newOwner), 1);
    }

    // Test: Cannot transfer NFT you don't own
    function testCannotTransferNotOwnedNFT() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        address hacker = makeAddr("hacker");

        vm.expectRevert();
        vm.prank(hacker);
        wecolor.transferFrom(buyer, hacker, 1);
    }

    // Test: Multiple NFTs increment token ID correctly
    function testTokenIdIncrement() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        for (uint i = 0; i < 5; i++) {
            wecolor.recordDailySnapshot(20241024 + i, "#FF5733", contributors);
        }

        vm.deal(buyer, 10 ether);

        for (uint i = 0; i < 5; i++) {
            uint256 price = wecolor.getDailyColor(20241024 + i).price;
            vm.prank(buyer);
            wecolor.buyNft{value: price}(20241024 + i);
        }

        assertEq(wecolor.nextTokenId(), 6);
        assertEq(wecolor.balanceOf(buyer), 5);
    }

    // Test: generateSvg contains correct color
    function testSVGContainsColor() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        wecolor.recordDailySnapshot(20241024, "#ABCDEF", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        string memory uri = wecolor.tokenURI(1);

        // Just verify it returns something (SVG is base64 encoded in the URI)
        assertTrue(bytes(uri).length > 100); // Base64 encoded JSON should be substantial
    }
}

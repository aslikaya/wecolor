// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorPurchaseTest
 * @notice Tests for NFT purchase functionality
 */
contract WeColorPurchaseTest is Test {
    WeColor public wecolor;
    address public owner;
    address public buyer;
    address public user1;
    address public user2;

    event NFTPurchased(uint256 indexed tokenId, uint256 indexed date, address buyer, uint256 price);

    function setUp() public {
        owner = address(this);
        buyer = makeAddr("buyer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        wecolor = new WeColor();

        // Setup a daily snapshot
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
    }

    // Test: Successfully buy NFT
    function testBuyNFT() public {
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        vm.expectEmit(true, true, false, true);
        emit NFTPurchased(1, 20241024, buyer, price);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Verify NFT ownership
        assertEq(wecolor.ownerOf(1), buyer);
        assertEq(wecolor.nextTokenId(), 2);

        // Verify daily color updated
        WeColor.DailyColor memory daily = wecolor.getDailyColor(20241024);
        assertTrue(daily.minted);
        assertEq(daily.buyer, buyer);
        assertEq(daily.tokenId, 1);

        // Verify tokenToDate mapping
        assertEq(wecolor.tokenIdToDate(1), 20241024);
    }

    // Test: Cannot buy already minted NFT
    function testCannotBuyAlreadyMintedNFT() public {
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Try to buy again
        address buyer2 = makeAddr("buyer2");
        vm.deal(buyer2, 10 ether);

        vm.expectRevert("Already minted");
        vm.prank(buyer2);
        wecolor.buyNft{value: price}(20241024);
    }

    // Test: Cannot buy with insufficient funds
    function testCannotBuyWithInsufficientFunds() public {
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, price - 1);

        vm.expectRevert("Insufficient funds");
        vm.prank(buyer);
        wecolor.buyNft{value: price - 1}(20241024);
    }

    // Test: Can buy with extra funds (overpayment)
    function testBuyWithOverpayment() public {
        uint256 price = wecolor.getDailyColor(20241024).price;
        uint256 overpayment = price + 1 ether;

        vm.deal(buyer, overpayment);

        vm.prank(buyer);
        wecolor.buyNft{value: overpayment}(20241024);

        assertEq(wecolor.ownerOf(1), buyer);
    }

    // Test: Buy multiple NFTs from different days
    function testBuyMultipleNFTs() public {
        // Setup second day
        address[] memory contributors = new address[](1);
        contributors[0] = user1;
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors);

        uint256 price1 = wecolor.getDailyColor(20241024).price;
        uint256 price2 = wecolor.getDailyColor(20241025).price;

        vm.deal(buyer, 10 ether);

        // Buy first NFT
        vm.prank(buyer);
        wecolor.buyNft{value: price1}(20241024);

        // Buy second NFT
        vm.prank(buyer);
        wecolor.buyNft{value: price2}(20241025);

        assertEq(wecolor.ownerOf(1), buyer);
        assertEq(wecolor.ownerOf(2), buyer);
        assertEq(wecolor.nextTokenId(), 3);
    }

    // Test: Cannot buy unrecorded day (division by zero in payment distribution)
    function testCannotBuyUnrecordedDay() public {
        vm.deal(buyer, 1 ether);

        // Unrecorded day has 0 contributors, which causes division by zero
        vm.expectRevert(); // Expect panic for division by zero
        vm.prank(buyer);
        wecolor.buyNft{value: 0}(20241099);
    }
}

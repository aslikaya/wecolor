// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorConfigTest
 * @notice Tests for configurable parameters and ownership
 */
contract WeColorConfigTest is Test {
    WeColor public wecolor;
    address public owner;
    address public nonOwner;
    address public newOwner;

    event BasePriceUpdated(uint256 oldPrice, uint256 newPrice);
    event PricePerContributorUpdated(uint256 oldPrice, uint256 newPrice);
    event TreasuryPercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        owner = address(this);
        nonOwner = makeAddr("nonOwner");
        newOwner = makeAddr("newOwner");

        wecolor = new WeColor();
    }

    // Test: Owner can update base price
    function testSetBasePrice() public {
        uint256 oldPrice = wecolor.basePrice();
        uint256 newPrice = 0.02 ether;

        vm.expectEmit(true, true, true, true);
        emit BasePriceUpdated(oldPrice, newPrice);

        wecolor.setBasePrice(newPrice);

        assertEq(wecolor.basePrice(), newPrice);
    }

    // Test: Non-owner cannot update base price
    function testNonOwnerCannotSetBasePrice() public {
        vm.expectRevert("Only owner can call this");
        vm.prank(nonOwner);
        wecolor.setBasePrice(0.02 ether);
    }

    // Test: Base price affects NFT pricing
    function testBasePriceAffectsNFTPricing() public {
        // Set new base price
        wecolor.setBasePrice(0.05 ether);

        // Record snapshot
        address[] memory contributors = new address[](2);
        contributors[0] = makeAddr("user1");
        contributors[1] = makeAddr("user2");

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        // Verify price uses new base price
        uint256 expectedPrice = 0.05 ether + (2 * 0.001 ether);
        assertEq(wecolor.getDailyColor(20241024).price, expectedPrice);
    }

    // Test: Owner can update price per contributor
    function testSetPricePerContributor() public {
        uint256 oldPrice = wecolor.pricePerContributor();
        uint256 newPrice = 0.002 ether;

        vm.expectEmit(true, true, true, true);
        emit PricePerContributorUpdated(oldPrice, newPrice);

        wecolor.setPricePerContributor(newPrice);

        assertEq(wecolor.pricePerContributor(), newPrice);
    }

    // Test: Non-owner cannot update price per contributor
    function testNonOwnerCannotSetPricePerContributor() public {
        vm.expectRevert("Only owner can call this");
        vm.prank(nonOwner);
        wecolor.setPricePerContributor(0.002 ether);
    }

    // Test: Price per contributor affects NFT pricing
    function testPricePerContributorAffectsNFTPricing() public {
        // Set new price per contributor
        wecolor.setPricePerContributor(0.005 ether);

        // Record snapshot with 3 contributors
        address[] memory contributors = new address[](3);
        contributors[0] = makeAddr("user1");
        contributors[1] = makeAddr("user2");
        contributors[2] = makeAddr("user3");

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        // Verify price uses new price per contributor
        uint256 expectedPrice = 0.01 ether + (3 * 0.005 ether);
        assertEq(wecolor.getDailyColor(20241024).price, expectedPrice);
    }

    // Test: Owner can update treasury percentage
    function testSetTreasuryPercentage() public {
        uint256 oldPercentage = wecolor.treasuryPercentage();
        uint256 newPercentage = 20;

        vm.expectEmit(true, true, true, true);
        emit TreasuryPercentageUpdated(oldPercentage, newPercentage);

        wecolor.setTreasuryPercentage(newPercentage);

        assertEq(wecolor.treasuryPercentage(), newPercentage);
    }

    // Test: Non-owner cannot update treasury percentage
    function testNonOwnerCannotSetTreasuryPercentage() public {
        vm.expectRevert("Only owner can call this");
        vm.prank(nonOwner);
        wecolor.setTreasuryPercentage(20);
    }

    // Test: Cannot set treasury percentage over 100
    function testCannotSetTreasuryPercentageOver100() public {
        vm.expectRevert("Percentage must be <= 100");
        wecolor.setTreasuryPercentage(101);
    }

    // Test: Treasury percentage of 100 is allowed
    function testTreasuryPercentage100Allowed() public {
        wecolor.setTreasuryPercentage(100);
        assertEq(wecolor.treasuryPercentage(), 100);
    }

    // Test: Treasury percentage affects payment distribution
    function testTreasuryPercentageAffectsDistribution() public {
        // Set treasury to 50%
        wecolor.setTreasuryPercentage(50);

        // Setup snapshot
        address contributor1 = makeAddr("contributor1");
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Treasury should have 50%
        uint256 expectedTreasury = (price * 50) / 100;
        assertEq(wecolor.treasuryBalance(), expectedTreasury);

        // Contributor should have 50% pending
        uint256 expectedContributorPayment = price - expectedTreasury;
        assertEq(wecolor.pendingRewards(contributor1), expectedContributorPayment);

        // Claim and verify balance
        uint256 contributor1BalanceBefore = contributor1.balance;
        vm.prank(contributor1);
        wecolor.claimReward();
        assertEq(contributor1.balance, contributor1BalanceBefore + expectedContributorPayment);
    }

    // Test: Owner can transfer ownership
    function testTransferOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(owner, newOwner);

        wecolor.transferOwnership(newOwner);

        assertEq(wecolor.owner(), newOwner);
    }

    // Test: Non-owner cannot transfer ownership
    function testNonOwnerCannotTransferOwnership() public {
        vm.expectRevert("Only owner can call this");
        vm.prank(nonOwner);
        wecolor.transferOwnership(newOwner);
    }

    // Test: Cannot transfer ownership to zero address
    function testCannotTransferOwnershipToZeroAddress() public {
        vm.expectRevert("New owner cannot be zero address");
        wecolor.transferOwnership(address(0));
    }

    // Test: New owner has owner privileges
    function testNewOwnerHasPrivileges() public {
        // Transfer ownership
        wecolor.transferOwnership(newOwner);

        // Old owner cannot call owner functions
        vm.expectRevert("Only owner can call this");
        wecolor.setBasePrice(0.02 ether);

        // New owner can call owner functions
        vm.prank(newOwner);
        wecolor.setBasePrice(0.02 ether);

        assertEq(wecolor.basePrice(), 0.02 ether);
    }

    // Test: New owner can record snapshots
    function testNewOwnerCanRecordSnapshots() public {
        wecolor.transferOwnership(newOwner);

        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        // New owner can record snapshot
        vm.prank(newOwner);
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        assertTrue(wecolor.getDailyColor(20241024).recorded);
    }

    // Test: Set base price to zero
    function testSetBasePriceToZero() public {
        wecolor.setBasePrice(0);
        assertEq(wecolor.basePrice(), 0);
    }

    // Test: Set price per contributor to zero
    function testSetPricePerContributorToZero() public {
        wecolor.setPricePerContributor(0);
        assertEq(wecolor.pricePerContributor(), 0);
    }

    // Test: Set treasury percentage to zero
    function testSetTreasuryPercentageToZero() public {
        wecolor.setTreasuryPercentage(0);
        assertEq(wecolor.treasuryPercentage(), 0);

        // Verify no treasury is collected
        address contributor1 = makeAddr("contributor1");
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Treasury should be 0
        assertEq(wecolor.treasuryBalance(), 0);
    }

    // Test: Multiple parameter updates
    function testMultipleParameterUpdates() public {
        wecolor.setBasePrice(0.05 ether);
        wecolor.setPricePerContributor(0.003 ether);
        wecolor.setTreasuryPercentage(25);

        assertEq(wecolor.basePrice(), 0.05 ether);
        assertEq(wecolor.pricePerContributor(), 0.003 ether);
        assertEq(wecolor.treasuryPercentage(), 25);
    }

    // Test: Parameters affect existing vs new snapshots
    function testParametersAffectOnlyNewSnapshots() public {
        // Record first snapshot with original prices
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 firstPrice = wecolor.getDailyColor(20241024).price;

        // Change prices
        wecolor.setBasePrice(0.02 ether);
        wecolor.setPricePerContributor(0.002 ether);

        // Record second snapshot with new prices
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors);
        uint256 secondPrice = wecolor.getDailyColor(20241025).price;

        // First snapshot price unchanged
        assertEq(firstPrice, 0.01 ether + 0.001 ether);

        // Second snapshot uses new prices
        assertEq(secondPrice, 0.02 ether + 0.002 ether);
    }
}

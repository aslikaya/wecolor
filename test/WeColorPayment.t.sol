// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorPaymentTest
 * @notice Tests for payment distribution and treasury
 */
contract WeColorPaymentTest is Test {
    WeColor public wecolor;
    address public owner;
    address public buyer;
    address public contributor1;
    address public contributor2;
    address public contributor3;

    event RewardDistributed(uint256 indexed date, address indexed contributor, uint256 amount);
    event TreasuryWithdrawn(address indexed owner, uint256 amount);

    // Allow test contract to receive ETH
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        buyer = makeAddr("buyer");
        contributor1 = makeAddr("contributor1");
        contributor2 = makeAddr("contributor2");
        contributor3 = makeAddr("contributor3");

        wecolor = new WeColor();
    }

    // Test: Payment distribution to contributors
    function testPaymentDistribution() public {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        uint256 contributor1BalanceBefore = contributor1.balance;
        uint256 contributor2BalanceBefore = contributor2.balance;

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Calculate expected payment
        uint256 treasuryAmount = (price * 10) / 100;
        uint256 distributionAmount = price - treasuryAmount;
        uint256 paymentPerPerson = distributionAmount / 2;

        assertEq(contributor1.balance, contributor1BalanceBefore + paymentPerPerson);
        assertEq(contributor2.balance, contributor2BalanceBefore + paymentPerPerson);
    }

    // Test: Treasury receives correct percentage
    function testTreasuryAccumulation() public {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 expectedTreasury = (price * 10) / 100;
        assertEq(wecolor.treasuryBalance(), expectedTreasury);
    }

    // Test: Multiple purchases accumulate treasury
    function testMultiplePurchasesTreasuryAccumulation() public {
        // Day 1
        address[] memory contributors1 = new address[](1);
        contributors1[0] = contributor1;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors1);

        // Day 2
        address[] memory contributors2 = new address[](2);
        contributors2[0] = contributor1;
        contributors2[1] = contributor2;
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors2);

        uint256 price1 = wecolor.getDailyColor(20241024).price;
        uint256 price2 = wecolor.getDailyColor(20241025).price;

        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price1}(20241024);

        vm.prank(buyer);
        wecolor.buyNft{value: price2}(20241025);

        uint256 expectedTreasury = ((price1 * 10) / 100) + ((price2 * 10) / 100);
        assertEq(wecolor.treasuryBalance(), expectedTreasury);
    }

    // Test: RewardDistributed events emitted correctly
    function testRewardDistributedEvents() public {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        uint256 treasuryAmount = (price * 10) / 100;
        uint256 distributionAmount = price - treasuryAmount;
        uint256 paymentPerPerson = distributionAmount / 2;

        vm.deal(buyer, 10 ether);

        vm.expectEmit(true, true, false, true);
        emit RewardDistributed(20241024, contributor1, paymentPerPerson);

        vm.expectEmit(true, true, false, true);
        emit RewardDistributed(20241024, contributor2, paymentPerPerson);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);
    }

    // Test: Withdraw from treasury
    function testWithdrawTreasury() public {
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 treasuryAmount = wecolor.treasuryBalance();
        uint256 ownerBalanceBefore = owner.balance;

        vm.expectEmit(true, false, false, true);
        emit TreasuryWithdrawn(owner, treasuryAmount);

        wecolor.withdrawTreasury(treasuryAmount);

        assertEq(owner.balance, ownerBalanceBefore + treasuryAmount);
        assertEq(wecolor.treasuryBalance(), 0);
    }

    // Test: Cannot withdraw more than treasury balance
    function testCannotWithdrawMoreThanBalance() public {
        vm.expectRevert("Insufficient treasury balance");
        wecolor.withdrawTreasury(1 ether);
    }

    // Test: Partial treasury withdrawal
    function testPartialTreasuryWithdrawal() public {
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 treasuryAmount = wecolor.treasuryBalance();
        uint256 withdrawAmount = treasuryAmount / 2;

        wecolor.withdrawTreasury(withdrawAmount);

        assertEq(wecolor.treasuryBalance(), treasuryAmount - withdrawAmount);
    }

    // Test: Payment distribution with many contributors
    function testPaymentDistributionManyContributors() public {
        address[] memory contributors = new address[](10);
        for (uint i = 0; i < 10; i++) {
            contributors[i] = address(uint160(1000 + i));
        }

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 treasuryAmount = (price * 10) / 100;
        uint256 distributionAmount = price - treasuryAmount;
        uint256 paymentPerPerson = distributionAmount / 10;

        // Check first and last contributor
        assertEq(contributors[0].balance, paymentPerPerson);
        assertEq(contributors[9].balance, paymentPerPerson);
    }
}

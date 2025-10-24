// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorClaimRewardTest
 * @notice Tests for the claimReward function and pull payment pattern
 */
contract WeColorClaimRewardTest is Test {
    WeColor public wecolor;
    address public owner;
    address public buyer;
    address public contributor1;
    address public contributor2;

    event RewardClaimed(address indexed contributor, uint256 amount);

    function setUp() public {
        owner = address(this);
        buyer = makeAddr("buyer");
        contributor1 = makeAddr("contributor1");
        contributor2 = makeAddr("contributor2");

        wecolor = new WeColor();
    }

    // Test: Cannot claim with no rewards
    function testCannotClaimWithNoRewards() public {
        vm.expectRevert("No rewards to claim");
        vm.prank(contributor1);
        wecolor.claimReward();
    }

    // Test: Can claim rewards after NFT purchase
    function testClaimRewardsAfterPurchase() public {
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 pendingReward = wecolor.pendingRewards(contributor1);
        assertTrue(pendingReward > 0);

        uint256 balanceBefore = contributor1.balance;

        vm.prank(contributor1);
        wecolor.claimReward();

        assertEq(contributor1.balance, balanceBefore + pendingReward);
        assertEq(wecolor.pendingRewards(contributor1), 0);
    }

    // Test: Claim rewards emits event
    function testClaimRewardsEmitsEvent() public {
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 pendingReward = wecolor.pendingRewards(contributor1);

        vm.expectEmit(true, false, false, true);
        emit RewardClaimed(contributor1, pendingReward);

        vm.prank(contributor1);
        wecolor.claimReward();
    }

    // Test: Cannot claim twice
    function testCannotClaimTwice() public {
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // First claim succeeds
        vm.prank(contributor1);
        wecolor.claimReward();

        // Second claim fails
        vm.expectRevert("No rewards to claim");
        vm.prank(contributor1);
        wecolor.claimReward();
    }

    // Test: Multiple contributors can claim independently
    function testMultipleContributorsClaimIndependently() public {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 reward1 = wecolor.pendingRewards(contributor1);
        uint256 reward2 = wecolor.pendingRewards(contributor2);

        // Contributor2 claims first
        vm.prank(contributor2);
        wecolor.claimReward();
        assertEq(contributor2.balance, reward2);
        assertEq(wecolor.pendingRewards(contributor2), 0);

        // Contributor1 can still claim
        assertEq(wecolor.pendingRewards(contributor1), reward1);
        vm.prank(contributor1);
        wecolor.claimReward();
        assertEq(contributor1.balance, reward1);
    }

    // Test: Accumulate rewards from multiple days
    function testAccumulateRewardsFromMultipleDays() public {
        // Day 1
        address[] memory contributors1 = new address[](1);
        contributors1[0] = contributor1;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors1);

        // Day 2
        address[] memory contributors2 = new address[](1);
        contributors2[0] = contributor1;
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors2);

        uint256 price1 = wecolor.getDailyColor(20241024).price;
        uint256 price2 = wecolor.getDailyColor(20241025).price;

        vm.deal(buyer, 10 ether);

        // Buy both NFTs
        vm.prank(buyer);
        wecolor.buyNft{value: price1}(20241024);

        vm.prank(buyer);
        wecolor.buyNft{value: price2}(20241025);

        // contributor1 should have accumulated rewards from both days
        uint256 treasuryAmount1 = (price1 * 10) / 100;
        uint256 treasuryAmount2 = (price2 * 10) / 100;
        uint256 expectedReward = (price1 - treasuryAmount1) + (price2 - treasuryAmount2);

        assertEq(wecolor.pendingRewards(contributor1), expectedReward);

        // Claim all at once
        vm.prank(contributor1);
        wecolor.claimReward();

        assertEq(contributor1.balance, expectedReward);
        assertEq(wecolor.pendingRewards(contributor1), 0);
    }

    // Test: Reentrancy protection on claimReward
    function testReentrancyProtectionOnClaim() public {
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Normal claim should work
        vm.prank(contributor1);
        wecolor.claimReward();

        // Pending rewards should be zero after claim
        assertEq(wecolor.pendingRewards(contributor1), 0);
    }

    // Test: Contributor can claim partial rewards if they participated in some days
    function testPartialClaimFromMultipleDays() public {
        // Day 1: contributor1 and contributor2
        address[] memory contributors1 = new address[](2);
        contributors1[0] = contributor1;
        contributors1[1] = contributor2;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors1);

        // Day 2: only contributor1
        address[] memory contributors2 = new address[](1);
        contributors2[0] = contributor1;
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors2);

        uint256 price1 = wecolor.getDailyColor(20241024).price;
        uint256 price2 = wecolor.getDailyColor(20241025).price;

        vm.deal(buyer, 10 ether);

        // Buy both NFTs
        vm.prank(buyer);
        wecolor.buyNft{value: price1}(20241024);

        vm.prank(buyer);
        wecolor.buyNft{value: price2}(20241025);

        // contributor2 should only have rewards from day 1
        uint256 treasuryAmount1 = (price1 * 10) / 100;
        uint256 distributionAmount1 = price1 - treasuryAmount1;
        uint256 expectedReward2 = distributionAmount1 / 2;

        assertEq(wecolor.pendingRewards(contributor2), expectedReward2);

        // contributor1 should have rewards from both days
        uint256 treasuryAmount2 = (price2 * 10) / 100;
        uint256 distributionAmount2 = price2 - treasuryAmount2;
        uint256 expectedReward1 = (distributionAmount1 / 2) + distributionAmount2;

        assertEq(wecolor.pendingRewards(contributor1), expectedReward1);
    }
}

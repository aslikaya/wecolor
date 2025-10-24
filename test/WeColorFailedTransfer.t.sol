// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title MaliciousContract
 * @notice Contract that rejects ETH transfers to test failure branches
 */
contract MaliciousContract {
    // No receive() or fallback() - will reject all ETH transfers
    // This is intentional to test the "Failed to Send ETH" branch
}

/**
 * @title WeColorFailedTransferTest
 * @notice Tests for failed transfer scenarios to achieve 100% branch coverage
 */
contract WeColorFailedTransferTest is Test {
    WeColor public wecolor;
    address public owner;
    address public buyer;
    address public goodContributor;
    MaliciousContract public maliciousContract;

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        buyer = makeAddr("buyer");
        goodContributor = makeAddr("goodContributor");

        wecolor = new WeColor();
        maliciousContract = new MaliciousContract();
    }

    // Test: Payment distribution fails when contributor cannot receive ETH
    function testPaymentDistributionFailsWithMaliciousContract() public {
        address[] memory contributors = new address[](2);
        contributors[0] = goodContributor;
        contributors[1] = address(maliciousContract); // This will reject ETH

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        // This should fail because maliciousContract cannot receive ETH
        vm.expectRevert("Failed to Send ETH");
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);
    }

    // Test: Treasury withdrawal fails when owner cannot receive ETH
    function testWithdrawTreasuryFailsWithMaliciousOwner() public {
        // Deploy a new WeColor contract with malicious owner
        vm.prank(address(maliciousContract));
        WeColor maliciousWeColor = new WeColor();

        // Setup snapshot (owner must call this)
        address[] memory contributors = new address[](1);
        contributors[0] = goodContributor;

        vm.prank(address(maliciousContract));
        maliciousWeColor.recordDailySnapshot(20241025, "#00FF00", contributors);

        // Buyer purchases NFT to accumulate treasury
        uint256 price2 = maliciousWeColor.getDailyColor(20241025).price;
        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        maliciousWeColor.buyNft{value: price2}(20241025);

        // Verify treasury accumulated
        uint256 treasuryBalance = maliciousWeColor.treasuryBalance();
        assertTrue(treasuryBalance > 0);

        // Now malicious contract (owner) tries to withdraw
        // This should fail because MaliciousContract cannot receive ETH
        vm.expectRevert("Failed to withdraw");
        vm.prank(address(maliciousContract));
        maliciousWeColor.withdrawTreasury(treasuryBalance);
    }

    // Test: Payment distribution succeeds with all normal addresses
    function testPaymentDistributionSucceedsWithNormalAddresses() public {
        address contributor1 = makeAddr("contributor1");
        address contributor2 = makeAddr("contributor2");

        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        uint256 balanceBefore1 = contributor1.balance;
        uint256 balanceBefore2 = contributor2.balance;

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Verify both received payment
        assertTrue(contributor1.balance > balanceBefore1);
        assertTrue(contributor2.balance > balanceBefore2);
    }

    // Test: Multiple malicious contracts in contributors array
    function testMultipleMaliciousContributors() public {
        MaliciousContract malicious2 = new MaliciousContract();

        address[] memory contributors = new address[](3);
        contributors[0] = goodContributor;
        contributors[1] = address(maliciousContract);
        contributors[2] = address(malicious2);

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        // Should fail on first malicious contract
        vm.expectRevert("Failed to Send ETH");
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);
    }

    // Test: Malicious contract as first contributor
    function testMaliciousContractFirstInLine() public {
        address[] memory contributors = new address[](2);
        contributors[0] = address(maliciousContract); // Malicious first
        contributors[1] = goodContributor;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        // Should fail immediately on first contributor
        vm.expectRevert("Failed to Send ETH");
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);
    }

    // Test: Malicious contract as last contributor
    function testMaliciousContractLastInLine() public {
        address contributor1 = makeAddr("contributor1");

        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = address(maliciousContract); // Malicious last

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        uint256 balanceBefore = contributor1.balance;

        // Should fail on second (last) contributor
        // First contributor doesn't get paid either due to revert
        vm.expectRevert("Failed to Send ETH");
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Verify first contributor didn't get paid (transaction reverted)
        assertEq(contributor1.balance, balanceBefore);
    }
}

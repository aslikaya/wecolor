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
 * @notice Tests for failed transfer scenarios with pull payment pattern
 * @dev Pull payment pattern protects against malicious contributors - they can't block others
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

    // Test: Malicious contract can't claim rewards but doesn't block others
    function testPaymentDistributionFailsWithMaliciousContract() public {
        address[] memory contributors = new address[](2);
        contributors[0] = goodContributor;
        contributors[1] = address(maliciousContract); // This will reject ETH when claiming

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        // NFT purchase succeeds (rewards are only allocated, not transferred)
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Good contributor can claim successfully
        uint256 reward = wecolor.pendingRewards(goodContributor);
        assertTrue(reward > 0);

        vm.prank(goodContributor);
        wecolor.claimReward();
        assertEq(goodContributor.balance, reward);

        // Malicious contract has pending rewards but can't claim them
        uint256 maliciousReward = wecolor.pendingRewards(address(maliciousContract));
        assertTrue(maliciousReward > 0);

        vm.expectRevert("Failed to send reward");
        vm.prank(address(maliciousContract));
        wecolor.claimReward();

        // Malicious contract's rewards are still pending (not lost)
        assertEq(wecolor.pendingRewards(address(maliciousContract)), maliciousReward);
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

    // Test: Payment allocation succeeds even with malicious contracts
    function testPaymentDistributionSucceedsWithNormalAddresses() public {
        address contributor1 = makeAddr("contributor1");
        address contributor2 = makeAddr("contributor2");

        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Verify both have pending rewards
        assertTrue(wecolor.pendingRewards(contributor1) > 0);
        assertTrue(wecolor.pendingRewards(contributor2) > 0);

        // Both can claim successfully
        vm.prank(contributor1);
        wecolor.claimReward();

        vm.prank(contributor2);
        wecolor.claimReward();

        // Verify both received payment
        assertTrue(contributor1.balance > 0);
        assertTrue(contributor2.balance > 0);
    }

    // Test: Multiple malicious contracts don't block NFT purchase
    function testMultipleMaliciousContributors() public {
        MaliciousContract malicious2 = new MaliciousContract();

        address[] memory contributors = new address[](3);
        contributors[0] = goodContributor;
        contributors[1] = address(maliciousContract);
        contributors[2] = address(malicious2);

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        // Purchase succeeds - rewards are allocated, not transferred
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // All have pending rewards
        assertTrue(wecolor.pendingRewards(goodContributor) > 0);
        assertTrue(wecolor.pendingRewards(address(maliciousContract)) > 0);
        assertTrue(wecolor.pendingRewards(address(malicious2)) > 0);

        // Good contributor can claim
        vm.prank(goodContributor);
        wecolor.claimReward();
        assertTrue(goodContributor.balance > 0);
    }

    // Test: Malicious contract as first contributor doesn't block others
    function testMaliciousContractFirstInLine() public {
        address[] memory contributors = new address[](2);
        contributors[0] = address(maliciousContract); // Malicious first
        contributors[1] = goodContributor;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        // Purchase succeeds
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // Good contributor can still claim even though malicious is first
        vm.prank(goodContributor);
        wecolor.claimReward();
        assertTrue(goodContributor.balance > 0);
    }

    // Test: Malicious contract as last contributor doesn't block others
    function testMaliciousContractLastInLine() public {
        address contributor1 = makeAddr("contributor1");

        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = address(maliciousContract); // Malicious last

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(buyer, 10 ether);

        // Purchase succeeds
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        // First contributor can claim successfully
        vm.prank(contributor1);
        wecolor.claimReward();
        assertTrue(contributor1.balance > 0);

        // Malicious contract still has pending rewards but can't claim
        assertTrue(wecolor.pendingRewards(address(maliciousContract)) > 0);
    }
}

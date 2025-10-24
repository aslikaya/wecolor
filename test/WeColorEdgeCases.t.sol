// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorEdgeCasesTest
 * @notice Tests for edge cases and failure scenarios
 */
contract WeColorEdgeCasesTest is Test {
    WeColor public wecolor;
    address public owner;

    // Allow test contract to receive ETH
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        wecolor = new WeColor();
    }

    // Test: Record snapshot with empty contributors array
    function testRecordSnapshotEmptyContributors() public {
        address[] memory contributors = new address[](0);

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        WeColor.DailyColor memory daily = wecolor.getDailyColor(20241024);
        assertEq(daily.contributors.length, 0);
        assertEq(daily.price, 0.01 ether); // Only base price
    }

    // Test: Buy NFT with empty contributors (should fail division by zero)
    function testBuyNFTEmptyContributorsFails() public {
        address[] memory contributors = new address[](0);
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        // This will fail with division by zero in distributePayment
        vm.expectRevert();
        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);
    }

    // Test: Record snapshot with single contributor
    function testRecordSnapshotSingleContributor() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        WeColor.DailyColor memory daily = wecolor.getDailyColor(20241024);
        assertEq(daily.contributors.length, 1);
        assertEq(daily.price, 0.01 ether + 0.001 ether);
    }

    // Test: Record snapshot with maximum contributors (gas test)
    function testRecordSnapshotManyContributors() public {
        address[] memory contributors = new address[](100);
        for (uint i = 0; i < 100; i++) {
            contributors[i] = address(uint160(1000 + i));
        }

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        WeColor.DailyColor memory daily = wecolor.getDailyColor(20241024);
        assertEq(daily.contributors.length, 100);
        assertEq(daily.price, 0.01 ether + (100 * 0.001 ether));
    }

    // Test: Record snapshot with very long color hex string
    function testRecordSnapshotLongColorHex() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        string memory longColor = "#FF5733FF5733FF5733FF5733FF5733";

        wecolor.recordDailySnapshot(20241024, longColor, contributors);

        assertEq(wecolor.getDailyColor(20241024).colorHex, longColor);
    }

    // Test: Record snapshot with special characters in color
    function testRecordSnapshotSpecialCharsColor() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        wecolor.recordDailySnapshot(20241024, "rgb(255,87,51)", contributors);

        assertEq(wecolor.getDailyColor(20241024).colorHex, "rgb(255,87,51)");
    }

    // Test: Buy NFT with exact price
    function testBuyNFTExactPrice() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, price);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        assertEq(wecolor.ownerOf(1), buyer);
    }

    // Test: Buy NFT with zero value (should fail)
    function testBuyNFTZeroValue() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        address buyer = makeAddr("buyer");

        vm.expectRevert("Insufficient funds");
        vm.prank(buyer);
        wecolor.buyNft{value: 0}(20241024);
    }

    // Test: Record snapshot on date 0
    function testRecordSnapshotDateZero() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        wecolor.recordDailySnapshot(0, "#FF5733", contributors);

        assertTrue(wecolor.getDailyColor(0).recorded);
    }

    // Test: Record snapshot with max uint256 date
    function testRecordSnapshotMaxDate() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        uint256 maxDate = type(uint256).max;
        wecolor.recordDailySnapshot(maxDate, "#FF5733", contributors);

        assertEq(wecolor.getDailyColor(maxDate).day, maxDate);
    }

    // Test: Withdraw exact treasury balance
    function testWithdrawExactTreasuryBalance() public {
        address[] memory contributors = new address[](1);
        contributors[0] = makeAddr("user1");

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 balance = wecolor.treasuryBalance();
        wecolor.withdrawTreasury(balance);

        assertEq(wecolor.treasuryBalance(), 0);
    }

    // Test: Withdraw zero from treasury
    function testWithdrawZeroTreasury() public {
        wecolor.withdrawTreasury(0);
        assertEq(wecolor.treasuryBalance(), 0);
    }

    // Test: getDailyColor for unrecorded date returns empty struct
    function testGetDailyColorUnrecordedDate() public {
        WeColor.DailyColor memory daily = wecolor.getDailyColor(99999999);

        assertEq(daily.day, 0);
        assertEq(daily.colorHex, "");
        assertEq(daily.contributors.length, 0);
        assertFalse(daily.recorded);
        assertFalse(daily.minted);
    }

    // Test: TokenIdToDate for unminted token returns 0
    function testTokenIdToDateUnminted() public {
        assertEq(wecolor.tokenIdToDate(999), 0);
    }

    // Test: Payment rounding with odd division
    function testPaymentRoundingOddDivision() public {
        address[] memory contributors = new address[](3);
        for (uint i = 0; i < 3; i++) {
            contributors[i] = address(uint160(1000 + i));
        }

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        uint256 balanceBefore0 = contributors[0].balance;

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 treasuryAmount = (price * 10) / 100;
        uint256 distributionAmount = price - treasuryAmount;
        uint256 expectedPayment = distributionAmount / 3;

        // Check payment received
        assertEq(contributors[0].balance, balanceBefore0 + expectedPayment);
    }

    // Test: Duplicate contributors in array
    function testDuplicateContributors() public {
        address user1 = makeAddr("user1");

        address[] memory contributors = new address[](3);
        contributors[0] = user1;
        contributors[1] = user1; // Duplicate
        contributors[2] = user1; // Duplicate

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        // Should still work, user1 will receive 3x payment
        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        uint256 balanceBefore = user1.balance;

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 treasuryAmount = (price * 10) / 100;
        uint256 distributionAmount = price - treasuryAmount;
        uint256 paymentPerPerson = distributionAmount / 3;

        // user1 should receive 3x payment (once for each entry)
        assertEq(user1.balance, balanceBefore + (paymentPerPerson * 3));
    }
}

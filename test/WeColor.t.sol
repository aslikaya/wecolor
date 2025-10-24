// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorTest
 * @notice Core functionality tests for WeColor contract
 */
contract WeColorTest is Test {
    WeColor public wecolor;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    // Events to test
    event DailySnapshotRecorded(uint256 indexed date, string colorHex, uint256 contributorCount, uint256 price);
    event NFTPurchased(uint256 indexed tokenId, uint256 indexed date, address buyer, uint256 price);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        wecolor = new WeColor();
    }

    // Test: Contract initializes correctly
    function testInitialization() public {
        assertEq(wecolor.owner(), owner);
        assertEq(wecolor.nextTokenId(), 1);
        assertEq(wecolor.treasuryBalance(), 0);
        assertEq(wecolor.name(), "WeColor");
        assertEq(wecolor.symbol(), "WCLR");
    }

    // Test: Record daily snapshot successfully
    function testRecordDailySnapshot() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        uint256 expectedPrice = 0.01 ether + (2 * 0.001 ether);

        vm.expectEmit(true, false, false, true);
        emit DailySnapshotRecorded(20241024, "#FF5733", 2, expectedPrice);

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        WeColor.DailyColor memory daily = wecolor.getDailyColor(20241024);

        assertEq(daily.day, 20241024);
        assertEq(daily.colorHex, "#FF5733");
        assertEq(daily.contributors.length, 2);
        assertEq(daily.price, expectedPrice);
        assertTrue(daily.recorded);
        assertFalse(daily.minted);
        assertEq(daily.tokenId, 0);
        assertEq(daily.buyer, address(0));
    }

    // Test: Cannot record same day twice
    function testCannotRecordSameDayTwice() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        vm.expectRevert("Already recorded");
        wecolor.recordDailySnapshot(20241024, "#00FF00", contributors);
    }

    // Test: Record multiple different days
    function testRecordMultipleDays() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors);
        wecolor.recordDailySnapshot(20241026, "#0000FF", contributors);

        assertEq(wecolor.getDailyColor(20241024).colorHex, "#FF5733");
        assertEq(wecolor.getDailyColor(20241025).colorHex, "#00FF00");
        assertEq(wecolor.getDailyColor(20241026).colorHex, "#0000FF");
    }

    // Test: Price calculation with different contributor counts
    function testPriceCalculation() public {
        address[] memory contributors1 = new address[](1);
        contributors1[0] = user1;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors1);
        assertEq(wecolor.getDailyColor(20241024).price, 0.01 ether + 0.001 ether);

        address[] memory contributors5 = new address[](5);
        for (uint i = 0; i < 5; i++) {
            contributors5[i] = address(uint160(100 + i));
        }
        wecolor.recordDailySnapshot(20241025, "#00FF00", contributors5);
        assertEq(wecolor.getDailyColor(20241025).price, 0.01 ether + (5 * 0.001 ether));
    }

    // Test: getDailyColor returns correct data
    function testGetDailyColor() public {
        address[] memory contributors = new address[](3);
        contributors[0] = user1;
        contributors[1] = user2;
        contributors[2] = user3;

        wecolor.recordDailySnapshot(20241024, "#ABCDEF", contributors);

        WeColor.DailyColor memory daily = wecolor.getDailyColor(20241024);
        assertEq(daily.day, 20241024);
        assertEq(daily.colorHex, "#ABCDEF");
        assertEq(daily.contributors[0], user1);
        assertEq(daily.contributors[1], user2);
        assertEq(daily.contributors[2], user3);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

/**
 * @title WeColorAccessTest
 * @notice Tests for access control and permissions
 */
contract WeColorAccessTest is Test {
    WeColor public wecolor;
    address public owner;
    address public nonOwner;

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        nonOwner = makeAddr("nonOwner");

        wecolor = new WeColor();
    }

    // Test: Owner can record daily snapshot
    function testOwnerCanRecordSnapshot() public {
        address[] memory contributors = new address[](1);
        contributors[0] = nonOwner;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        assertTrue(wecolor.getDailyColor(20241024).recorded);
    }

    // Test: Non-owner cannot record daily snapshot
    function testNonOwnerCannotRecordSnapshot() public {
        address[] memory contributors = new address[](1);
        contributors[0] = owner;

        vm.expectRevert("Only owner can call this");
        vm.prank(nonOwner);
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
    }

    // Test: Owner can withdraw treasury
    function testOwnerCanWithdrawTreasury() public {
        // Setup and buy NFT to accumulate treasury
        address[] memory contributors = new address[](1);
        contributors[0] = nonOwner;
        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        uint256 price = wecolor.getDailyColor(20241024).price;
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 10 ether);

        vm.prank(buyer);
        wecolor.buyNft{value: price}(20241024);

        uint256 treasuryAmount = wecolor.treasuryBalance();

        // Owner withdraws
        wecolor.withdrawTreasury(treasuryAmount);

        assertEq(wecolor.treasuryBalance(), 0);
    }

    // Test: Non-owner cannot withdraw treasury
    function testNonOwnerCannotWithdrawTreasury() public {
        vm.expectRevert("Only owner can call this");
        vm.prank(nonOwner);
        wecolor.withdrawTreasury(1 ether);
    }

    // Test: Owner is set correctly on deployment
    function testOwnerSetOnDeployment() public {
        assertEq(wecolor.owner(), owner);
    }

    // Test: OnlyOwner modifier blocks all non-owner calls
    function testOnlyOwnerModifierBlocks() public {
        address[] memory contributors = new address[](1);
        contributors[0] = owner;

        address[] memory attackers = new address[](5);
        for (uint i = 0; i < 5; i++) {
            attackers[i] = address(uint160(2000 + i));
        }

        for (uint i = 0; i < attackers.length; i++) {
            vm.expectRevert("Only owner can call this");
            vm.prank(attackers[i]);
            wecolor.recordDailySnapshot(20241024 + i, "#FF5733", contributors);

            vm.expectRevert("Only owner can call this");
            vm.prank(attackers[i]);
            wecolor.withdrawTreasury(0.01 ether);
        }
    }
}

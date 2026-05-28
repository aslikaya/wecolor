// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title WeColorLazyMintTest
 * @notice Tests for signature-based lazy minting (buyNftWithSignature)
 */
contract WeColorLazyMintTest is Test {
    WeColor public wecolor;
    uint256 public ownerPrivateKey;
    address public ownerAddr;
    address public buyer;
    address public user1;
    address public user2;
    address public user3;

    // Events
    event DailySnapshotRecorded(uint256 indexed date, string colorHex, uint256 contributorCount, uint256 price);
    event NFTPurchased(uint256 indexed tokenId, uint256 indexed date, address buyer, uint256 price);
    event RewardAllocated(uint256 indexed date, address indexed contributor, uint256 amount);

    function setUp() public {
        // Create owner with known private key for signing
        ownerPrivateKey = 0xA11CE;
        ownerAddr = vm.addr(ownerPrivateKey);

        vm.prank(ownerAddr);
        wecolor = new WeColor();

        buyer = makeAddr("buyer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Fund the buyer
        vm.deal(buyer, 10 ether);
    }

    /// @dev Helper to sign snapshot data with the owner key
    function _signSnapshot(uint256 date, string memory colorHex, address[] memory contributors)
        internal
        view
        returns (bytes memory)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(date, colorHex, contributors));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, ethSignedHash);
        return abi.encodePacked(r, s, v);
    }

    // ==================== Happy Path ====================

    function testBuyNftWithValidSignature() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        uint256 expectedPrice = 0.01 ether + (2 * 0.001 ether); // 0.012 ETH

        vm.prank(buyer);
        wecolor.buyNftWithSignature{value: expectedPrice}(date, colorHex, contributors, signature);

        // Verify snapshot was recorded
        WeColor.DailyColor memory daily = wecolor.getDailyColor(date);
        assertEq(daily.day, date);
        assertEq(daily.colorHex, colorHex);
        assertEq(daily.contributors.length, 2);
        assertEq(daily.contributors[0], user1);
        assertEq(daily.contributors[1], user2);
        assertTrue(daily.recorded);
        assertTrue(daily.minted);
        assertEq(daily.buyer, buyer);
        assertEq(daily.tokenId, 1);
        assertEq(daily.price, expectedPrice);

        // Verify NFT ownership
        assertEq(wecolor.ownerOf(1), buyer);
        assertEq(wecolor.nextTokenId(), 2);

        // Verify token URI works
        string memory uri = wecolor.tokenURI(1);
        assertTrue(bytes(uri).length > 0);
    }

    function testBuyNftWithSignaturePaymentDistribution() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        uint256 price = 0.012 ether;

        vm.prank(buyer);
        wecolor.buyNftWithSignature{value: price}(date, colorHex, contributors, signature);

        // Treasury gets 10%
        uint256 expectedTreasury = (price * 10) / 100; // 0.0012 ETH
        assertEq(wecolor.treasuryBalance(), expectedTreasury);

        // Each contributor gets equal share of remaining 90%
        uint256 distributionAmount = price - expectedTreasury; // 0.0108 ETH
        uint256 perContributor = distributionAmount / 2; // 0.0054 ETH

        assertEq(wecolor.pendingRewards(user1), perContributor);
        assertEq(wecolor.pendingRewards(user2), perContributor);
    }

    function testBuyNftWithSignatureThreeContributors() public {
        address[] memory contributors = new address[](3);
        contributors[0] = user1;
        contributors[1] = user2;
        contributors[2] = user3;

        uint256 date = 20250528;
        string memory colorHex = "#ABCDEF";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        uint256 expectedPrice = 0.01 ether + (3 * 0.001 ether); // 0.013 ETH

        vm.prank(buyer);
        wecolor.buyNftWithSignature{value: expectedPrice}(date, colorHex, contributors, signature);

        WeColor.DailyColor memory daily = wecolor.getDailyColor(date);
        assertEq(daily.contributors.length, 3);
        assertEq(daily.price, expectedPrice);
        assertTrue(daily.minted);
    }

    function testBuyNftWithSignatureExcessPayment() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        uint256 date = 20250528;
        string memory colorHex = "#FF0000";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        uint256 price = 0.011 ether;
        uint256 overpay = 0.05 ether;

        vm.prank(buyer);
        wecolor.buyNftWithSignature{value: overpay}(date, colorHex, contributors, signature);

        // Should still work — overpayment is distributed
        assertTrue(wecolor.getDailyColor(date).minted);
    }

    function testBuyNftWithSignatureEmitsEvents() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);
        uint256 price = 0.012 ether;

        vm.expectEmit(true, false, false, true);
        emit DailySnapshotRecorded(date, colorHex, 2, price);

        vm.expectEmit(true, true, false, true);
        emit NFTPurchased(1, date, buyer, price);

        vm.prank(buyer);
        wecolor.buyNftWithSignature{value: price}(date, colorHex, contributors, signature);
    }

    // ==================== Signature Validation ====================

    function testRevertInvalidSigner() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";

        // Sign with a random non-owner key
        uint256 fakeKey = 0xBAD;
        bytes32 messageHash = keccak256(abi.encodePacked(date, colorHex, contributors));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeKey, ethSignedHash);
        bytes memory fakeSig = abi.encodePacked(r, s, v);

        vm.prank(buyer);
        vm.expectRevert("Invalid signature");
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, colorHex, contributors, fakeSig);
    }

    function testRevertTamperedColor() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        uint256 date = 20250528;
        // Sign with correct color
        bytes memory signature = _signSnapshot(date, "#FF5733", contributors);

        // Submit with different color
        vm.prank(buyer);
        vm.expectRevert("Invalid signature");
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, "#00FF00", contributors, signature);
    }

    function testRevertTamperedContributors() public {
        address[] memory realContributors = new address[](2);
        realContributors[0] = user1;
        realContributors[1] = user2;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";
        bytes memory signature = _signSnapshot(date, colorHex, realContributors);

        // Submit with different contributors (attacker tries to be sole contributor)
        address[] memory fakeContributors = new address[](1);
        fakeContributors[0] = buyer;

        vm.prank(buyer);
        vm.expectRevert("Invalid signature");
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, colorHex, fakeContributors, signature);
    }

    function testRevertTamperedDate() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        // Sign for one date
        bytes memory signature = _signSnapshot(20250528, "#FF5733", contributors);

        // Submit for different date
        vm.prank(buyer);
        vm.expectRevert("Invalid signature");
        wecolor.buyNftWithSignature{value: 0.011 ether}(20250529, "#FF5733", contributors, signature);
    }

    // ==================== Replay Protection ====================

    function testRevertReplaySignature() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        // First purchase succeeds
        vm.prank(buyer);
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, colorHex, contributors, signature);

        // Replay fails
        vm.prank(buyer);
        vm.expectRevert("Already recorded");
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, colorHex, contributors, signature);
    }

    // ==================== Edge Cases ====================

    function testRevertNoContributors() public {
        address[] memory contributors = new address[](0);

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        vm.prank(buyer);
        vm.expectRevert("No contributors");
        wecolor.buyNftWithSignature{value: 0.01 ether}(date, colorHex, contributors, signature);
    }

    function testRevertInsufficientFunds() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        // Price should be 0.012 ETH, send less
        vm.prank(buyer);
        vm.expectRevert("Insufficient funds");
        wecolor.buyNftWithSignature{value: 0.005 ether}(date, colorHex, contributors, signature);
    }

    // ==================== Backwards Compatibility ====================

    function testOldBuyNftStillWorksForRecordedDays() public {
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        uint256 date = 20250528;
        uint256 price = 0.012 ether;

        // Record via old owner-only path
        vm.prank(ownerAddr);
        wecolor.recordDailySnapshot(date, "#FF5733", contributors);

        // Buy via old buyNft
        vm.prank(buyer);
        wecolor.buyNft{value: price}(date);

        assertTrue(wecolor.getDailyColor(date).minted);
        assertEq(wecolor.ownerOf(1), buyer);
    }

    function testCannotUseLazyMintForAlreadyRecordedDay() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";

        // Record via old path
        vm.prank(ownerAddr);
        wecolor.recordDailySnapshot(date, colorHex, contributors);

        // Try lazy mint — should fail because already recorded
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        vm.prank(buyer);
        vm.expectRevert("Already recorded");
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, colorHex, contributors, signature);
    }

    // ==================== Ownership Transfer ====================

    function testSignatureInvalidAfterOwnershipTransfer() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";

        // Sign with current owner
        bytes memory signature = _signSnapshot(date, colorHex, contributors);

        // Transfer ownership
        address newOwner = makeAddr("newOwner");
        vm.prank(ownerAddr);
        wecolor.transferOwnership(newOwner);

        // Old owner's signature should now be rejected
        vm.prank(buyer);
        vm.expectRevert("Invalid signature");
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, colorHex, contributors, signature);
    }

    function testNewOwnerSignatureWorksAfterTransfer() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        uint256 date = 20250528;
        string memory colorHex = "#FF5733";

        // Transfer ownership to a known key
        uint256 newOwnerKey = 0xB0B;
        address newOwner = vm.addr(newOwnerKey);
        vm.prank(ownerAddr);
        wecolor.transferOwnership(newOwner);

        // Sign with new owner
        bytes32 messageHash = keccak256(abi.encodePacked(date, colorHex, contributors));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(newOwnerKey, ethSignedHash);
        bytes memory newSig = abi.encodePacked(r, s, v);

        vm.prank(buyer);
        wecolor.buyNftWithSignature{value: 0.011 ether}(date, colorHex, contributors, newSig);

        assertTrue(wecolor.getDailyColor(date).minted);
    }

    // ==================== Multiple Days ====================

    function testBuyMultipleDaysWithSignatures() public {
        address[] memory contributors = new address[](1);
        contributors[0] = user1;

        bytes memory sig1 = _signSnapshot(20250528, "#FF0000", contributors);
        bytes memory sig2 = _signSnapshot(20250529, "#00FF00", contributors);
        bytes memory sig3 = _signSnapshot(20250530, "#0000FF", contributors);

        vm.startPrank(buyer);
        wecolor.buyNftWithSignature{value: 0.011 ether}(20250528, "#FF0000", contributors, sig1);
        wecolor.buyNftWithSignature{value: 0.011 ether}(20250529, "#00FF00", contributors, sig2);
        wecolor.buyNftWithSignature{value: 0.011 ether}(20250530, "#0000FF", contributors, sig3);
        vm.stopPrank();

        assertEq(wecolor.getDailyColor(20250528).colorHex, "#FF0000");
        assertEq(wecolor.getDailyColor(20250529).colorHex, "#00FF00");
        assertEq(wecolor.getDailyColor(20250530).colorHex, "#0000FF");
        assertEq(wecolor.nextTokenId(), 4);
    }
}

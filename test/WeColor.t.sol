// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WeColor} from "../src/WeColor.sol";

contract WeColorTest is Test {
    WeColor public wecolor;
    address public owner;
    address public user1;
    address public user2;

    // Test contract'ının ETH alabilmesi için
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        wecolor = new WeColor();
    }
    
    function testRecordSnapshot() public {
        // Test: Backend can record snapshot
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        // Control: is it recorded?
        WeColor.DailyColor memory daily = wecolor.getDailyColor(20241024);

        assertEq(daily.day, 20241024);
        assertEq(daily.colorHex, "#FF5733");
        assertTrue(daily.recorded);
    }
    
    function testBuyNFT() public {
        // First record the snapshot
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);

        // get the price
        uint256 price = wecolor.getDailyColor(20241024).price;

        // user1 NFT satın alır
        vm.deal(user1, 10 ether); // user1'e para ver
        vm.prank(user1); // user1 olarak işlem yap
        wecolor.buyNft{value: price}(20241024);

        // control: is NFT minted?
        assertEq(wecolor.ownerOf(1), user1);

        // Kontrol: Treasury'de %10 birikti mi?
        uint256 expectedTreasury = (price * 10) / 100;
        assertEq(wecolor.treasuryBalance(), expectedTreasury);
    }

    function testTreasuryWithdraw() public {
        // Önce snapshot kaydet ve NFT sat
        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;

        wecolor.recordDailySnapshot(20241024, "#FF5733", contributors);
        uint256 price = wecolor.getDailyColor(20241024).price;

        vm.deal(user1, 10 ether);
        vm.prank(user1);
        wecolor.buyNft{value: price}(20241024);

        // Treasury'den para çek
        uint256 treasuryAmount = wecolor.treasuryBalance();
        uint256 ownerBalanceBefore = address(this).balance;

        wecolor.withdrawTreasury(treasuryAmount);

        // Kontrol: Owner parası arttı mı?
        assertEq(address(this).balance, ownerBalanceBefore + treasuryAmount);
        assertEq(wecolor.treasuryBalance(), 0);
    }
}


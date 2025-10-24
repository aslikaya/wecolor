//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title WeColor
 * @notice Daily collective color NFT contract
 */
contract WeColor is ERC721 {
    address public owner;
    uint256 public nextTokenId;
    uint256 public constant PRICE_PER_CONTRIBUTOR = 0.001 ether;
    uint256 public constant BASE_PRICE = 0.01 ether;
    uint256 public constant TREASURY_PERCENTAGE = 10;
    uint256 public treasuryBalance;

    DailyColor[] dailyColors;
    mapping(uint256 => DailyColor) public dateToDailyColor;
    mapping(uint256 => uint256) public tokenIdToDate;

    struct DailyColor {
        uint256 day;
        string colorHex; // final collective color
        address[] contributors;
        bool minted;
        uint256 price;
        address buyer;
        uint256 tokenId;
        bool recorded;
    }

    // Events
    event DailySnapshotRecorded(uint256 indexed date, string colorHex, uint256 contributorCount, uint256 price);
    event NFTPurchased(uint256 indexed tokenId, uint256 indexed date, address buyer, uint256 price);
    event RewardDistributed(uint256 indexed date, address indexed contributor, uint256 amount);
    event TreasuryWithdrawn(address indexed owner, uint256 amount);

    constructor() ERC721("WeColor", "WCLR") {
        owner = msg.sender;
        nextTokenId = 1;
    }

    function buyNft(uint256 date) external payable {
        DailyColor storage dateColor = dateToDailyColor[date];
        require(!dateColor.minted, "Already minted");
        require(msg.value >= dateColor.price, "Insufficient funds");
        _mint(msg.sender, nextTokenId);
        tokenIdToDate[nextTokenId] = date;
        dateColor.tokenId = nextTokenId;
        dateColor.minted = true;
        dateColor.buyer = msg.sender;

        emit NFTPurchased(nextTokenId, date, msg.sender, msg.value);

        nextTokenId++;
        distributePayment(date);
    }

    function distributePayment(uint256 date) private {
        DailyColor storage dateColor = dateToDailyColor[date];
        uint256 totalContributors = dateColor.contributors.length;

        // For treasury
        uint256 treasuryAmount = (msg.value * TREASURY_PERCENTAGE) / 100;
        treasuryBalance += treasuryAmount;

        // The rest to be distributed to contributors
        uint256 distributionAmount = msg.value - treasuryAmount;
        uint256 paymentPerPerson = distributionAmount / totalContributors;

        for (uint256 i = 0; i < totalContributors; i++) {
            address contributor = dateColor.contributors[i];
            (bool sent, ) = contributor.call{value: paymentPerPerson}("");
            require(sent, "Failed to Send ETH");

            emit RewardDistributed(date, contributor, paymentPerPerson);
        }
    }

    function recordDailySnapshot(
        uint256 date,
        string calldata colorHex,
        address[] calldata contributors
    ) external onlyOwner {
        require(!dateToDailyColor[date].recorded, "Already recorded");
        uint256 price = BASE_PRICE +
            contributors.length *
            PRICE_PER_CONTRIBUTOR;

        dateToDailyColor[date] = DailyColor({
            day: date,
            colorHex: colorHex,
            contributors: contributors,
            price: price,
            minted: false,
            recorded: true,
            tokenId: 0,
            buyer: address(0)
        });

        dailyColors.push(dateToDailyColor[date]);

        emit DailySnapshotRecorded(date, colorHex, contributors.length, price);
    }

    function generateSvg(uint256 date) internal view returns (string memory) {
        DailyColor storage dailycolor = dateToDailyColor[date];

        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',
                    '<rect fill="',
                    dailycolor.colorHex,
                    '" width="400" height="400"/>',
                    '<text x="200" y="50" text-anchor="middle" fill="white" font-size="24">WeColor</text>',
                    '<text x="200" y="100" text-anchor="middle" fill="white" font-size="20">',
                    Strings.toString(date),
                    "</text>",
                    '<text x="200" y="150" text-anchor="middle" fill="white" font-size="18">',
                    Strings.toString(dailycolor.contributors.length),
                    " contributors</text>",
                    "</svg>"
                )
            );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        uint256 date = tokenIdToDate[tokenId];
        require(date != 0, "Token does not exist");

        string memory svg = generateSvg(date);

        string memory json = string(
            abi.encodePacked(
                '{"name": "WeColor #',
                Strings.toString(tokenId),
                '",',
                '"description": "Collective color created on ',
                Strings.toString(date),
                '",',
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function getDailyColor(uint256 date) public view returns (DailyColor memory) {
        return dateToDailyColor[date];
    }

    /// @notice Owner to withdraw money from treasury
    function withdrawTreasury(uint256 amount) external onlyOwner {
        require(amount <= treasuryBalance, "Insufficient treasury balance");
        treasuryBalance -= amount;

        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Failed to withdraw");

        emit TreasuryWithdrawn(owner, amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtistCommissionAuctionNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public tokenToCommission;
    mapping(uint256 => uint256) public tokenToHighestBid;
    mapping(uint256 => address) public tokenToHighestBidder;

    event CommissionSet(uint256 indexed tokenId, uint256 commissionAmount);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 amount);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function setCommission(uint256 tokenId, uint256 commissionAmount) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved or owner");
        
        tokenToCommission[tokenId] = commissionAmount;
        emit CommissionSet(tokenId, commissionAmount);
    }

    function getCommission(uint256 tokenId) external view returns (uint256) {
        return tokenToCommission[tokenId];
    }

    function placeBid(uint256 tokenId) external payable {
        require(_exists(tokenId), "Token ID does not exist");
        require(msg.value > tokenToHighestBid[tokenId], "Bid must be higher than current highest bid");

        if (tokenToHighestBid[tokenId] > 0) {
            // Refund the previous highest bidder
            address payable previousHighestBidder = payable(tokenToHighestBidder[tokenId]);
            previousHighestBidder.transfer(tokenToHighestBid[tokenId]);
        }

        tokenToHighestBid[tokenId] = msg.value;
        tokenToHighestBidder[tokenId] = msg.sender;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Token ID does not exist");
        require(tokenToHighestBid[tokenId] > 0, "No bids have been placed");

        address winner = tokenToHighestBidder[tokenId];
        uint256 winningAmount = tokenToHighestBid[tokenId];

        // Transfer NFT to the winner
        _safeTransfer(ownerOf(tokenId), winner, tokenId, "");

        // Reset auction data
        tokenToHighestBid[tokenId] = 0;
        tokenToHighestBidder[tokenId] = address(0);

        emit AuctionEnded(tokenId, winner, winningAmount);
    }
}
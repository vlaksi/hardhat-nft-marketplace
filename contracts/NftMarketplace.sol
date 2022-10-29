// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();

/**
 * NftMarketplace contract is about few next things
 *
 * 1. 'listItem':           List NFTs on the marketplace
 * 2. 'butItem':            But the NFTs
 * 3. 'cancelItem':         Cancel a listing
 * 4. 'updateListing':      Update
 * 5. 'withdrawProceeds':   Withdraw payment for my bought NFTs (withdraw money :D)
 */
contract NftMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // NFT Contract address -> NFT Token ID -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // Seller address -> Amount earned
    // Track how much many each user earn
    mapping(address => uint256) private s_proceeds;

    /////////////////////
    ////   Modifers  ////
    /////////////////////

    modifier notListed(address nftAddress, uint256 tokenId) {
        // Before function, apply notListed modifier
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }

        // Then continue a function
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        // Before function, apply isListed modifier
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }

        // Then continue a function
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    /////////////////////
    //  Main Functions //
    /////////////////////

    /*
     * @notice Method for listing NFT
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     * @dev With this approach, users still can hold their NFTs when they list them.
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) {
        // Check price
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }

        // Check approvals
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }

        // Update listings
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /*
     * @notice Method for buying listing
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to fail
     * Ideally you'd also have a `createOffer` functionality.
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
    // isNotOwner(nftAddress, tokenId, msg.sender)
    // nonReentrant
    {
        // Check if buyer have a enough money
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }

        // Give a money from a buyer to the seller
        s_proceeds[listedItem.seller] += msg.value;

        // We don't just send the seller the money !!
        // We use 'pull over push pattern' ie. Shift the risk associated with transferring ether to the user.
        // We do not send a money to user  !!
        // We force them to withdraw money !!
        // https://fravoll.github.io/solidity-patterns/pull_over_push.html
        delete (s_listings[nftAddress][tokenId]);
        // Send NFT
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId); // Will throw an error if transaction is not possible (and not lost any funds)
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }
}

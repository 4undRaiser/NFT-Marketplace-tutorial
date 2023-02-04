// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace {
    using Counters for Counters.Counter;
    Counters.Counter private numOfListing;

    struct NFTListing {
        ERC721 nft;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool forSale;
    }

    mapping(uint256 => NFTListing) private listings;

    modifier onlyNftOwner(uint256 _Id) {
        require(msg.sender == listings[_Id].seller);
        _;
    }

    // this function will list an artifact into the marketplace
    function listNFT(
        ERC721 _nft,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require(_price > 0, "NFTMarket: price must be greater than 0");
        numOfListing.increment();
        listings[numOfListing.current()] = NFTListing(
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false
        );
    }

    // this function will cancel the listing. it also has checks to make sure only the owner of the listing can cancel the listing from the market place
    function sell(uint256 _Id) external onlyNftOwner(_Id) {
        NFTListing storage listing = listings[_Id];
        require(
            listing.seller == msg.sender,
            "Only the nft owner can sell nft"
        );
        require(listing.forSale == false);
        listing.forSale = true;
        listing.nft.transferFrom(msg.sender, address(this), _Id);
        
    }

    function cancel(uint256 _Id) external onlyNftOwner(_Id) {
        NFTListing storage listing = listings[_Id];
        require(listing.seller == msg.sender);
        require(listing.forSale == true);
        listing.forSale = false;
        listing.nft.transferFrom(address(this), msg.sender, _Id);
    }

    // this function will facilitate the purchasing of a listing
    function buyNFT(uint256 _Id) external payable {
        NFTListing storage listing = listings[_Id];
        require(_Id > 0 && _Id <= numOfListing.current(), "item doesn't exist");
        require(
            msg.value >= listing.price,
            "not enough balance for this transaction"
        );
        require(listing.forSale != false, "item is not for sell");
        require(listing.seller != msg.sender, "You cannot buy your own nft");
        listing.seller = msg.sender;
        listing.forSale = false;
        listing.nft.transferFrom(address(this), msg.sender, listing.tokenId);
        (bool success, ) = payable(listing.seller).call{value: listing.price}(
            ""
        );
        require(success, "Transfer failed");
    }

    // this function will get the listings in the market place
    function getNFTListing(uint256 _Id)
        public
        view
        returns (NFTListing memory)
    {
        return listings[_Id];
    }

    // get list of items
    function getListinglength() public view returns (uint256) {
        return numOfListing.current();
    }
}

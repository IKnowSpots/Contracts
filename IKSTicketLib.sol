//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


library ticket { 
    enum NftType {
        ERC721,
        ERC1155
    }

    struct Ticket {
        address host;
        uint supply;
        uint remaining;
        uint price;
        address owner;
        uint ticketId;
        bool isActive; //indicates paused/active event
        bool isPublished;
        bool isShortlist; //if the event is open or shortlist-based
        bool isExistingTicket;
        bool isStaking;
        NftType nftType;
    }

    struct existing721NFT {
        NftType nftType;
        string collectionName;
        address contractAddress;
        string uri;
    }

    struct existing1155NFT {
        NftType nftType;
        string collectionName;
        address contractAddress;
        uint tokenId;
        string uri;
    }

    struct Reward {
        uint rewardId;
        address host;
        uint supply;
        bool isClaimed;
        bool isCryptoBound;
        uint price;
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// struct is a event
// tokens are event tickets
// create struct, increase ticketId and mint tickets for usual event hosting
// create struct and increase ticketId for pre existing tickets

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IIKS.sol";
import "./interfaces/IFeaturedEvents.sol";
import "./IKSTicketLib.sol";

contract IKS is IIKS, ERC1155URIStorage, ERC1155Holder {
    address public host;
    address public factoryContract;
    IFeaturedEvents featuredEvents;

    // host is a contract deployer
    constructor(address _featuredContract, address _factoryContract) ERC1155("") {
        host = payable(tx.origin);
        factoryContract = payable(_factoryContract);
        featuredEvents = IFeaturedEvents(_featuredContract);
    }

    using ticket for ticket.Ticket;
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenId;
    // Counters.Counter private _rewardId;

    uint public _tokenId;
    uint public _rewardId;

    mapping(uint => ticket.Ticket) public idToTicket;
    mapping(uint => ticket.existing721NFT) public idToExisting721;
    mapping(uint => ticket.existing1155NFT) public idToExisting1155;
    mapping(uint => address[]) public idToShortlist;
    mapping(address => bool) public isValidator;

    modifier onlyHost() {
        require(host == tx.origin);
        _;
    }

    modifier onlyValidator() {
        require(isValidator[tx.origin] == true);
        _;
    }

    modifier onlyFactoryContract() {
        require(factoryContract == msg.sender);
        _;
    }

    function addValidator(address _address) public onlyHost {
        isValidator[_address] = true;
    }

    function removeValidator(address _address) public onlyHost {
        isValidator[_address] = false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // mints erc1155 Nft collection
    function mintTickets(uint _price, uint _supply, bool _isShortlist, bool _isStaking, string memory _tokenURI) public onlyHost {
        // _tokenId.increment();
        _tokenId++;
        // uint256 currentToken = _tokenId.current();
        uint currentToken = _tokenId;
        _mint(host, currentToken, _supply, "");
        _setURI(currentToken, _tokenURI);
        idToTicket[currentToken] = ticket.Ticket(host, _supply, _supply, _price, host, currentToken, false, false, _isShortlist, false, _isStaking, ticket.NftType.ERC1155);
    }

    // publishes NFT collection as event tickets
    function publishTickets(uint _ticketId) public onlyHost {
        _safeTransferFrom(host, address(this), _ticketId, idToTicket[_ticketId].supply, "");
        idToTicket[_ticketId].isActive = true;
        idToTicket[_ticketId].isPublished = true;
    }

    // publishes existing ERC721 NFT collection as event tickets
    function publishExistingNFT721Tickets(string memory _collectionName, address _contract, bool isStaking, string memory _tokenURI) public onlyHost {
        // _tokenId.increment();
        _tokenId++;
        // uint256 currentToken = _tokenId.current();
        uint currentToken = _tokenId;
        idToTicket[currentToken] = ticket.Ticket(host, 0, 0, 0, address(0), currentToken, true, true, false, true, isStaking, ticket.NftType.ERC721);
        idToExisting721[currentToken] = ticket.existing721NFT(ticket.NftType.ERC721, _collectionName, _contract, _tokenURI);
    }

    // publishes existing ERC1155 NFT collection as event tickets
    function publishExistingNFT1155Tickets(string memory _collectionName, address _contract, uint256 _nftId, bool isStaking, string memory _tokenURI) public onlyHost {
        _tokenId++;
        // uint256 currentToken = _tokenId.current();
        uint currentToken = _tokenId;
        idToTicket[currentToken] = ticket.Ticket(host, 0, 0, 0, address(0), currentToken, true, true, false, true, isStaking, ticket.NftType.ERC1155);
        idToExisting1155[currentToken] = ticket.existing1155NFT(ticket.NftType.ERC1155, _collectionName, _contract, _nftId, _tokenURI);
    }

    // pauses an active event
    function pauseActiveEvent(uint _ticketId) public onlyHost {
        idToTicket[_ticketId].isActive = false;
    }

    // runs a paused event
    function runPausedEvent(uint _ticketId) public onlyHost {
        idToTicket[_ticketId].isActive = true;
    } 

    // updates shortlist for a shortlist event
    function updateShortlist(uint _ticketId, address[] memory _shortlist) public { 
        idToShortlist[_ticketId] = _shortlist;
    }

    function pushFeaturedEvent(uint _ticketId) public onlyHost {
        ticket.Ticket storage currentTick = idToTicket[_ticketId];
        featuredEvents.createFeaturedEvent(currentTick.supply, currentTick.remaining, currentTick.price, host, currentTick.ticketId, currentTick.isActive, currentTick.isShortlist, currentTick.isExistingTicket);
    }

    // anyone can buy Nfts and amount goes to contract deployer
    function buyTicket(uint _ticketId) public payable onlyFactoryContract { 
        ticket.Ticket storage currentTick = idToTicket[_ticketId];
        if(currentTick.isShortlist == true) {
            shortlistBuy(_ticketId);
        } else {

        require(msg.value == currentTick.price, "");
        require(currentTick.remaining > 0, "");
        _safeTransferFrom(address(this), tx.origin, _ticketId, 1, "");
        currentTick.owner = payable(tx.origin);
        currentTick.remaining--;
        // payable(address(this)).transfer(currentTick.price);
        emit Purchased(_ticketId, msg.sender);
        }
    }

    // shortlist users can claim NFTs 
    function shortlistBuy(uint _ticketId) private returns (bool) {
        ticket.Ticket memory currentTick = idToTicket[_ticketId];
        for (uint i = 0; i < currentTick.supply; i++) {
            address iAddress = idToShortlist[_ticketId][i];
            if (tx.origin == iAddress) {
                require(currentTick.remaining > 0, "");
                require(balanceOf(msg.sender, _ticketId) < 1, "");
                _safeTransferFrom(address(this), tx.origin, _ticketId, 1, "");
                currentTick.owner = tx.origin;
                currentTick.remaining = currentTick.remaining - 1;
                return true;
            }
        }
        return false;
    }

    function fetchAllEvents() public view returns (ticket.Ticket[] memory) {
        uint counter = 0;

        ticket.Ticket[] memory tickets = new ticket.Ticket[](_tokenId);
        // for (uint256 i = 0; i < _tokenId.current(); i++) {
        for (uint i = 0; i < _tokenId; i++) {
            uint currentId = i + 1;
            ticket.Ticket storage currentItem = idToTicket[currentId];
            tickets[counter] = currentItem;
            counter++;
        }
        return tickets;
    }

    function checkIn(uint _ticketId) public view returns (uint) {
        ticket.Ticket memory currentTick = idToTicket[_ticketId];
        require(currentTick.owner == msg.sender);
        uint otp = generateOTP();
        return otp;
    }

    function generateOTP() public pure returns (uint) {
        uint otp = 200100;
        return otp;
    }

    function validateOTP(uint ticketId) public onlyValidator {
        ticket.Ticket memory currentTick = idToTicket[ticketId];
        payable(currentTick.owner).transfer(currentTick.price);
    }

    mapping (uint256 => ticket.Reward) public idToReward;
    mapping (uint256 => mapping (address => bool)) public isWhitelist; 

    function mintReward(uint _supply, string memory _tokenURI, bool _isCryptoBound, uint _price) public payable onlyHost {
        // _rewardId.increment();
        // uint256 currentToken = _rewardId.current();
        require(_price == msg.value);
        _rewardId++;
        uint currentToken = _rewardId;
        _mint(host, currentToken, _supply, "");
        _setURI(currentToken, _tokenURI);
        _safeTransferFrom(host, address(this), currentToken, _supply, "");
        idToReward[currentToken] = ticket.Reward(currentToken, host, _supply, false, _isCryptoBound, _price);
    }

    function updateWhitelist(uint _rewardToken, address _user) public onlyHost {
        isWhitelist[_rewardToken][_user] = true;
    }

    function claimReward(uint _rewardToken) public {
        ticket.Reward memory currentReward = idToReward[_rewardToken];
        require(isWhitelist[currentReward.rewardId][msg.sender]);

        if (currentReward.isCryptoBound == true ) {
            _safeTransferFrom(address(this), tx.origin, _rewardToken, 1, "");
            currentReward.isClaimed = true;
            payable(msg.sender).transfer(currentReward.price);
        }

        else {
            _safeTransferFrom(address(this), tx.origin, _rewardToken, 1, "");
            currentReward.isClaimed = true;
        }
    }

    function fetchAllRewards() public view returns (ticket.Reward[] memory) {
        uint counter = 0;

        ticket.Reward[] memory rewards = new ticket.Reward[](_rewardId);
        // for (uint256 i = 0; i < _tokenId.current(); i++) {
        for (uint i = 0; i < _rewardId; i++) {
            uint currentId = i + 1;
            ticket.Reward storage currentItem = idToReward[currentId];
            rewards[counter] = currentItem;
            counter++;
        }
        return rewards;
    }

    // returns all purchased tickets of a user
    function fetchPurchasedTickets() public view returns (ticket.Ticket[] memory) {
        uint counter = 0;
        uint length;

        // for (uint256 i = 0; i < _tokenId.current(); i++) {
        for (uint i = 0; i < _tokenId; i++) {
            if (idToTicket[i + 1].owner == tx.origin) {
                length++;
            }
            if (idToTicket[i + 1].isExistingTicket == true && idToTicket[i + 1].nftType == ticket.NftType.ERC721) {
                IERC721 nft = IERC721(idToExisting721[i+1].contractAddress);
                if(nft.balanceOf(msg.sender) > 0) {
                    length++;
                }
            }
            if (idToTicket[i + 1].isExistingTicket == true && idToTicket[i + 1].nftType == ticket.NftType.ERC1155) {
                IERC1155 nft = IERC1155(idToExisting1155[i+1].contractAddress);
                if(nft.balanceOf(msg.sender, idToExisting1155[i+1].tokenId) > 0) {
                    length++;
                }
            }
        }

        ticket.Ticket[] memory tickets = new ticket.Ticket[](length);
        // for (uint256 i = 0; i < _tokenId.current(); i++) {
        for (uint i = 0; i < _tokenId; i++) {
            if (idToTicket[i + 1].owner == tx.origin) {
                uint currentId = i + 1;
                ticket.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
            // 
            if (idToTicket[i + 1].isExistingTicket == true && idToTicket[i + 1].nftType == ticket.NftType.ERC721) {
                IERC721 nft = IERC721(idToExisting721[i+1].contractAddress);
                if(nft.balanceOf(msg.sender) > 0) {
                    uint currentId = i + 1;
                    ticket.Ticket storage currentItem = idToTicket[currentId];
                    tickets[counter] = currentItem;
                    counter++;
                }
            }
            if (idToTicket[i + 1].isExistingTicket == true && idToTicket[i + 1].nftType == ticket.NftType.ERC1155) {
                IERC1155 nft = IERC1155(idToExisting1155[i+1].contractAddress);
                if(nft.balanceOf(msg.sender, idToExisting1155[i+1].tokenId) > 0) {
                    uint currentId = i + 1;
                    ticket.Ticket storage currentItem = idToTicket[currentId];
                    tickets[counter] = currentItem;
                    counter++;
                }
            }
            // 
        }
        return tickets;
    }

    function withdraw() external onlyHost {
        uint256 amount = address(this).balance;
        require(amount > 0);
        (bool sent, ) = payable(host).call{value: amount}("");
        require(sent, "failed");
    }    
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IIKS.sol";
import "./interfaces/IFeaturedEvents.sol";


contract FeaturedEvents is Ownable, IFeaturedEvents {

    mapping(uint256 => featured.Ticket) public idToTicket;
    uint featuredId;

    function createFeaturedEvent(uint _supply, uint _remaining, uint _price, address _host, uint256 _ticketId, bool _isActive, bool _isPrivateEvent, bool _isExistingTicket) public {
        featuredId++;
        idToTicket[featuredId] = featured.Ticket(_host, _supply, _remaining, _price, _host, _ticketId, _isActive, true, _isPrivateEvent, _isExistingTicket, featuredId, false);
    }

    function buyTicket(uint _ticketId, address _eventifyAddress) public payable {
        address eventifyContract = _eventifyAddress;
        IIKS eventify = IIKS(eventifyContract);
        eventify.buyTicket(_ticketId);
    }

    function markAsOver(uint _featuredId) public onlyOwner {
        idToTicket[_featuredId].isOver = true;
    }

    function fetchFeaturedEvents() public view returns (featured.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == false) {
                length++;
            }
        }

        featured.Ticket[] memory tickets = new featured.Ticket[](length);
        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == false) {
                uint256 currentId = i + 1;
                featured.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }

    function fetchPastFeaturedEvents() public view returns (featured.Ticket[] memory) {
        uint256 counter = 0;
        uint256 length;

        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == true) {
                length++;
            }
        }

        featured.Ticket[] memory tickets = new featured.Ticket[](length);
        for (uint256 i = 0; i < featuredId; i++) {
            if(idToTicket[i + 1].isPublished == true && idToTicket[i + 1].isOver == true) {
                uint256 currentId = i + 1;
                featured.Ticket storage currentItem = idToTicket[currentId];
                tickets[counter] = currentItem;
                counter++;
            }
        }
        return tickets;
    }
}
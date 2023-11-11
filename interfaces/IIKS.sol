//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../IKSTicketLib.sol";

interface IIKS {
    
    event Purchased(uint ticketId, address indexed to);

    function mintTickets(uint _price, uint _supply, bool _isShortlist, bool _isStaking, string memory _tokenURI) external;

    function publishTickets(uint _ticketId) external;

    function pauseActiveEvent(uint _ticketId) external;

    function runPausedEvent(uint _ticketId) external;

    function buyTicket(uint _ticketId) external payable;

    function pushFeaturedEvent(uint _ticketId) external;

    function fetchPurchasedTickets() external returns (ticket.Ticket[] memory);
}
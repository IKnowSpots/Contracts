// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// host is the actual wallet that deploy this eventify
// owner is the factory contract that deploys this contract

import "./IKS.sol";
import "./FeaturedEvents.sol";
import "./interfaces/IFactoryIKS.sol";
import "./interfaces/IIKS.sol";

contract FactoryIKS is IFactoryIKS {

    IKS[] public contracts;
    address[] public addresses;
    address public featuredEventsInstanceAddress;
    FeaturedEvents public featuredEventsInstance;

    mapping (address => string) public addressToUsername;
    mapping (string => address) public usernameToAddress;
    mapping (address => uint) public hostAddressToContractId;
    mapping (string => bool) public usernameExist;
    mapping (address => bool) public hasDeployed;
    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isWhitelistOperator;
    mapping (address => address[]) public userToHostPurchased;

    struct FeaturedRequest {
        address host;
        uint ticketId;
        bool isApproved;
    }

    uint public featuredRequestId;
    mapping(uint => FeaturedRequest) public idToFeaturedRequest;

    address owner;

    constructor() {
        isWhitelistOperator[msg.sender] = true;
        featuredEventsInstance = new FeaturedEvents();
        featuredEventsInstanceAddress = address(featuredEventsInstance);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function setWhitelistOperator(address _user) public onlyOwner {
        isWhitelistOperator[_user] = true;
    }

    function whitelistUser(address _user) public {
        require(isWhitelistOperator[msg.sender] == true);
        isWhitelisted[_user] = true;
        emit UserWhitelisted(_user, msg.sender);
    }

    modifier isUserWhitelisted() {
        require(isWhitelisted[msg.sender] == true, "You are not whitelisted");
        _;
    }

    function deployIKS(string memory _username) public returns (address) {
        require(hasDeployed[msg.sender] != true);
        IKS t = new IKS(featuredEventsInstanceAddress, address(this));
        contracts.push(t);
        addressToUsername[msg.sender] =_username;
        usernameToAddress[_username] = msg.sender;
        usernameExist[_username] = true;
        hostAddressToContractId[msg.sender] = contracts.length - 1;
        hasDeployed[msg.sender] = true;
        emit IKSDeployed(msg.sender, address(t));
        return address(t);
    }

    function getHostsContractAddress(address _address) public view returns (address) {
        uint id = hostAddressToContractId[_address];
        return address(contracts[id]);
    }

    function buy(string memory _username, uint _ticketId) public payable {
        address hostAddr = usernameToAddress[_username];
        uint contractId = hostAddressToContractId[hostAddr];
        contracts[contractId].buyTicket{value: msg.value}(_ticketId);
        userToHostPurchased[msg.sender].push(hostAddr);
    }

    function raiseFeaturedRequest(uint256 _ticketId) public {
        featuredRequestId++;
        idToFeaturedRequest[featuredRequestId] = FeaturedRequest(msg.sender, _ticketId, false);
    }

    function approveFeaturedEvents(address host, uint _ticketId) public onlyOwner {
        uint id = hostAddressToContractId[host];
        contracts[id].pushFeaturedEvent(_ticketId);
        idToFeaturedRequest[_ticketId].isApproved == false;
    }

    function fetchAllFeaturedRequest() public view returns (FeaturedRequest[] memory) {
        uint counter = 0;

        FeaturedRequest[] memory tickets = new FeaturedRequest[](featuredRequestId);
        for (uint i = 0; i < featuredRequestId; i++) {
                uint currentId = i + 1;
                FeaturedRequest storage currentItem = idToFeaturedRequest[currentId];
                tickets[counter] = currentItem;
                counter++;
        }
        return tickets;
    }

    function userToHostPurchasedArray(address _address) public view returns (address[] memory) {
        address[] memory arr;
        arr = userToHostPurchased[_address];
        return arr;
    }

    function contractsArray() public view returns (IKS[] memory) {
        IKS[] memory arr =  new IKS[](contracts.length-1);
        arr = contracts;
        return arr;
    }
}

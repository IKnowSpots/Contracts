//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFactoryIKS {
    
    event UserWhitelisted(address indexed user, address indexed by);
    event IKSDeployed(address indexed user, address indexed contractAddress);

    function setWhitelistOperator(address _user) external;
    
    function whitelistUser(address _user) external;

    function deployIKS(string memory _username) external returns (address);
}
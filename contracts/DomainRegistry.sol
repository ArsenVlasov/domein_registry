// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./Ownable.sol";

contract DomainRegistry is Ownable {
    uint256 public totalDomains;
    uint256 public totalReservedDomains;

    struct Domain {
        address controller;
        uint256 deposit;
    }

    mapping(string => Domain) private domains;

    event DomainReserved(string indexed domainName, address indexed controller, uint256 deposit);
    event DepositChanged(string indexed domainName, uint256 newDeposit);
    event DomainControlTransferred(string indexed domainName, address indexed newController);
    event DomainReleased(string indexed domainName, address indexed controller, uint256 refundAmount);

    constructor() {}

    function reserveDomain(string memory domainName, uint256 initialDeposit) public payable {
        require(msg.value >= initialDeposit, "Insufficient initial deposit");
        require(domains[domainName].controller == address(0), "Domain already reserved");
        require(isTopLevelDomain(domainName), "Domain name must be a top-level domain");

        domains[domainName] = Domain({
            controller: msg.sender,
            deposit: initialDeposit
        });
        totalDomains++;
        totalReservedDomains++;
        
        emit DomainReserved(domainName, msg.sender, initialDeposit);
    }

    function isTopLevelDomain(string memory domainName) private pure returns (bool) {
    bytes memory domainBytes = bytes(domainName);
    for(uint i = 0; i < domainBytes.length; i++) {
        if(domainBytes[i] == '.') {
            return false;
        }
    }
    return true;
    }

    function changeDeposit(string memory domainName, uint256 newDeposit) public payable {
        require(domains[domainName].controller == msg.sender, "Only the domain controller can change deposit");
        require(msg.value >= newDeposit, "Insufficient deposit amount");

        domains[domainName].deposit = newDeposit;
        emit DepositChanged(domainName, newDeposit);
    }

    function transferDomainControl(string memory domainName, address newController) public {
        require(domains[domainName].controller == msg.sender, "Only the domain controller can transfer control");
        require(newController != address(0), "Invalid controller address");

        domains[domainName].controller = newController;
        emit DomainControlTransferred(domainName, newController);
    }

    function releaseDomain(string memory domainName) public {
        require(domains[domainName].controller == msg.sender, "Only the domain controller can release the domain");

        address payable controller = payable(msg.sender);
        uint256 refundAmount = domains[domainName].deposit;

        delete domains[domainName];
        totalReservedDomains--;
        controller.transfer(refundAmount);

        emit DomainReleased(domainName, msg.sender, refundAmount);
    }

    function getDomainController(string memory domainName) public view returns (address) {
        return domains[domainName].controller;
    }

    function getDomainDeposit(string memory domainName) public view returns (uint256) {
        return domains[domainName].deposit;
    }

    function getTotalDomains() public view returns (uint256) {
        return totalDomains;
    }

    function getTotalReservedDomains() public view returns (uint256) {
        return totalReservedDomains;
    }

    function withdrawFunds() public onlyOwner payable {
        address payable contractOwner = payable(owner);
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        contractOwner.transfer(balance);
    }
}
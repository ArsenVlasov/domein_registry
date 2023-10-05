// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./Ownable.sol";
import "./DomainValidator.sol";

contract DomainRegistry is Ownable {
    uint256 private totalReservedDomains;
    uint256 private minDeposit;

    struct Domain {
        address controller;
        uint256 deposit;
    }

    mapping(string => Domain) private domains;

    event DomainReserved(string indexed domainName, address indexed controller, uint256 deposit);
    event DepositChanged(string indexed domainName, uint256 newDeposit);
    event DomainControlTransferred(string indexed domainName, address indexed newController);
    event DomainReleased(string indexed domainName, address indexed controller, uint256 refundAmount);

    constructor(uint256 _minDeposit) payable  {
        minDeposit = _minDeposit;
    }

    modifier onlyController(string memory domainName) {
        require(domains[domainName].controller == msg.sender, "Only the domain controller can execute it");
        _;
    }

    modifier sufficientDeposit(uint256 amount) {
        require(msg.value >= amount, "Insufficient deposit amount");
        _;
    }

    function reserveDomain(string memory domainName) public payable  {
        string memory cleanDomainName = DomainValidator.stripProtocolOnlyAssembly(domainName);
        require(DomainValidator.isValidDomain(cleanDomainName), "Invalid domain name format");
        require(hasValidParentDomain(cleanDomainName), "Parent domain must exist");
        require(domains[cleanDomainName].controller == address(0), "Domain already reserved");

        domains[cleanDomainName] = Domain({
            controller: msg.sender,
            deposit: msg.value 
        });
        totalReservedDomains++;

        emit DomainReserved(cleanDomainName, msg.sender, msg.value);
    }

    function reserveDomainOnlyAssymbly(string memory domainName) public payable  {
        string memory cleanDomainName = DomainValidator.stripProtocolOnlyAssembly(domainName);
        require(DomainValidator.isValidDomain(cleanDomainName), "Invalid domain name format");
        require(hasValidParentDomain(cleanDomainName), "Parent domain must exist");
        require(domains[cleanDomainName].controller == address(0), "Domain already reserved");

        domains[cleanDomainName] = Domain({
            controller: msg.sender,
            deposit: msg.value 
        });
        totalReservedDomains++;

        emit DomainReserved(cleanDomainName, msg.sender, msg.value);
    }

    function hasValidParentDomain(string memory domainName) private view returns (bool) {
        string memory parentDomain = DomainValidator.getParentDomain(domainName);
        if(bytes(parentDomain).length == 0) {
            return true;
        }
        return domains[parentDomain].controller != address(0);
    }


    function isDomainRegistered(string memory domainName) external view returns (bool) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        return domains[cleanDomainName].controller != address(0);
    }

    function changeDeposit(string memory domainName, uint256 newDeposit) public payable onlyController(domainName) sufficientDeposit(newDeposit) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        domains[cleanDomainName].deposit = msg.value;
        emit DepositChanged(cleanDomainName, msg.value);
    }

    function transferDomainControl(string memory domainName, address newController) public onlyController(domainName) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        require(newController != address(0), "Invalid controller address");

        domains[cleanDomainName].controller = newController;
        emit DomainControlTransferred(cleanDomainName, newController);
    }

    function releaseDomain(string memory domainName) public onlyController(domainName) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        address payable controller = payable(msg.sender);
        uint256 refundAmount = domains[cleanDomainName].deposit;

        delete domains[cleanDomainName];
        totalReservedDomains--;
        controller.transfer(refundAmount);

        emit DomainReleased(domainName, msg.sender, refundAmount);
    }

    function getDomainController(string memory domainName) public view returns (address) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        return domains[cleanDomainName].controller;
    }

    function getDomainDeposit(string memory domainName) public view returns (uint256) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        return domains[cleanDomainName].deposit;
    }

    function getTotalReservedDomains() public view returns (uint256) {
        return totalReservedDomains;
    }
}

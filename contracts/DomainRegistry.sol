// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./Ownable.sol";

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

    constructor(uint256 _minDeposit) {
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

    function reserveDomain(string memory domainName) public payable sufficientDeposit(minDeposit) {
        require(domains[domainName].controller == address(0), "Domain already reserved");
        require(isTopLevelDomain(domainName), "Domain name must be a top-level domain");

        domains[domainName] = Domain({
            controller: msg.sender,
            deposit: msg.value 
        });
        totalReservedDomains++;

        emit DomainReserved(domainName, msg.sender, msg.value);
    }

    function isTopLevelDomain(string memory domainName) private pure returns (bool) {
        bytes memory domainBytes = bytes(domainName);
        for (uint i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == '.') {
                return false;
            }
        }
        return true;
    }

    function changeDeposit(string memory domainName, uint256 newDeposit) public payable onlyController(domainName) sufficientDeposit(newDeposit) {
        domains[domainName].deposit = msg.value;
        emit DepositChanged(domainName, msg.value);
    }

    function transferDomainControl(string memory domainName, address newController) public onlyController(domainName) {
        require(newController != address(0), "Invalid controller address");

        domains[domainName].controller = newController;
        emit DomainControlTransferred(domainName, newController);
    }

    function releaseDomain(string memory domainName) public onlyController(domainName) {
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

    function getTotalReservedDomains() public view returns (uint256) {
        return totalReservedDomains;
    }
}

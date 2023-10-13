// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "hardhat/console.sol";
import "./Ownable.sol";
import "./DomainValidator.sol";

contract DomainRegistry is Ownable {
    uint256 private totalReservedDomains;
    uint256 private minDeposit;

    struct Domain {
        address controller;
        uint256 deposit;
        bytes32[] childDomains;
    }

    mapping(string => Domain) domains;

    constructor(uint256 _minDeposit) payable {
        minDeposit = _minDeposit;
    }

    modifier onlyController(string memory domainName) {
        require(domains[domainName].controller == msg.sender,"Only the domain controller can execute it");
        _;
    }

    modifier sufficientDeposit(uint256 amount) {
        require(msg.value >= amount, "Insufficient deposit amount");
        _;
    }

    function reserveDomain(string memory domainName) public payable {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        require(DomainValidator.isValidDomain(cleanDomainName),"Invalid domain name format");
        require(domains[cleanDomainName].controller == address(0),"Domain already reserved");

        string memory parentDomain = DomainValidator.getParentDomain(cleanDomainName); 
        require(keccak256(abi.encodePacked(parentDomain)) == keccak256(abi.encodePacked("")) || domains[parentDomain].controller != address(0), "Parent domain must exist");

        if (keccak256(abi.encodePacked(parentDomain)) != keccak256(abi.encodePacked("")) && domains[parentDomain].controller != address(0)) {
            domains[parentDomain].childDomains.push(keccak256(abi.encodePacked(cleanDomainName)));
        }

        domains[cleanDomainName] = Domain({
            controller: msg.sender,
            deposit: msg.value,
            childDomains: new bytes32[](0)
        });
    }

    function releaseDomain(string memory domainName) public onlyController(domainName) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        require(domains[cleanDomainName].childDomains.length == 0,"Remove child domains first");
        require(domains[cleanDomainName].controller != address(0),"Domain is not reserved");

        removeChildFromParentDomain(cleanDomainName);

        address payable controller = payable(msg.sender);
        uint256 refundAmount = domains[cleanDomainName].deposit;
        delete domains[cleanDomainName];

        controller.transfer(refundAmount);
    }

    function removeChildFromParentDomain(string memory childDomain) private {
        string memory parentDomain = DomainValidator.getParentDomain(childDomain);
        bytes32 hashedChild = keccak256(abi.encodePacked(childDomain));
        bytes32 hashedParent = keccak256(abi.encodePacked(parentDomain));

        if (hashedParent != keccak256(abi.encodePacked("")) &&domains[parentDomain].controller != address(0)) {
            bytes32[] storage childDomains = domains[parentDomain].childDomains;
            uint index;
            bool found = false;

            for (uint i = 0; i < childDomains.length; i++) {
                if (childDomains[i] == hashedChild) {
                    index = i;
                    found = true;
                    break;
                }
            }

            if (found) {
                assembly {
                    let len := sload(childDomains.slot)
                    if lt(index, sub(len, 1)) {
                        let data := add(add(childDomains.slot, 1), index)
                        let lastElem := add(
                            add(childDomains.slot, 1),
                            sub(len, 1)
                        )
                        sstore(data, sload(lastElem))
                    }
                    sstore(childDomains.slot, sub(len, 1))
                }
            }
        }
    }

    function changeDeposit(string memory domainName, uint256 newDeposit) public payable onlyController(domainName) sufficientDeposit(newDeposit) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        domains[cleanDomainName].deposit = msg.value;
    }

    function transferDomainControl(string memory domainName, address newController) public onlyController(domainName) {
        string memory cleanDomainName = DomainValidator.stripProtocol(domainName);
        require(newController != address(0), "Invalid controller address");

        domains[cleanDomainName].controller = newController;
    }

}

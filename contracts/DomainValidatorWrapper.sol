// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./DomainValidator.sol";

contract DomainValidatorWrapper {
    using DomainValidator for string;

    function stripProtocol(string memory domainName) public pure returns (string memory) {
        return domainName.stripProtocol();
    }

    function splitDomain(string memory domainName) public pure returns (string[] memory) {
        return domainName.splitDomain();
    }

    function getParentDomain(string memory domainName) public pure returns (string memory) {
        return domainName.getParentDomain();
    }

    function isValidDomain(string memory domainName) public pure returns (bool) {
        return domainName.isValidDomain();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ChildDomainManager {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    mapping(string => EnumerableSet.Bytes32Set) private childDomains;

    function addChildDomain(string memory parent, string memory child) external {
        childDomains[parent].add(keccak256(bytes(child)));
    }

    function removeChildDomain(string memory parent, string memory child) external {
        childDomains[parent].remove(keccak256(bytes(child)));
    }

    function hasChildDomain(string memory parent) external view returns (bool) {
        return childDomains[parent].length() > 0;
    }
}


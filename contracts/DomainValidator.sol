// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library DomainValidator {
    function stripProtocol(string memory domainName) internal pure returns (string memory) {
        bytes memory domainBytes = bytes(domainName);

        if (domainBytes.length < 8) {
            return domainName;
        }
        if (
            domainBytes[0] == "h" &&
            domainBytes[1] == "t" &&
            domainBytes[2] == "t" &&
            domainBytes[3] == "p" &&
            domainBytes[4] == "s" &&
            domainBytes[5] == ":" &&
            domainBytes[6] == "/" &&
            domainBytes[7] == "/"
        ) {
            bytes memory strippedBytes = new bytes(domainBytes.length - 8);
            for (uint i = 8; i < domainBytes.length; i++) {
                strippedBytes[i - 8] = domainBytes[i];
            }
            return string(strippedBytes);
        }

        return domainName;
    }

    function stripProtocolOnlyAssembly(string memory domainName) public pure returns (string memory) {
        bytes memory domainBytes = bytes(domainName);
        if (domainBytes.length < 8) {
            return domainName;
        }

        bool isHttps;
        
        assembly {
            let ptr := add(domainBytes, 0x20)
            isHttps := and(
                and(
                    and(
                        eq(mload(ptr), 0x6874747073),
                        eq(and(mload(add(ptr, 0x3)), 0xFFFFFF), 0x3a2f2f)
                    ),
                    gt(mload(domainBytes), 7)
                ),
                lt(mload(domainBytes), 0xFFFFFFFFFFFFFFFF)
            )
        }
        
        if (isHttps) {
            bytes memory strippedBytes = new bytes(domainBytes.length - 8);
            assembly {
                let source := add(add(domainBytes, 0x20), 8)
                let destination := add(strippedBytes, 0x20)
                let end := add(source, sub(mload(domainBytes), 8))
                
                for { } lt(source, end) { }
                {
                    mstore(destination, mload(source))
                    source := add(source, 0x20)
                    destination := add(destination, 0x20)
                }
            }
            return string(strippedBytes);
        }
        return domainName;
    }


    function splitDomain(string memory domainName) internal pure returns (string[] memory) {
        bytes memory domainBytes = bytes(domainName);
        uint count = 1;
        for (uint i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == ".") {
                count++;
            }
        }
        string[] memory parts = new string[](count);
        uint start = 0;
        uint index = 0;
        for (uint i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == "." || i == domainBytes.length - 1) {
                uint length = i - start + (i == domainBytes.length - 1 ? 1 : 0);
                parts[index] = new string(length);
                bytes memory partBytes = bytes(parts[index]);
                for (uint j = 0; j < length; j++) {
                    partBytes[j] = domainBytes[start + j];
                }
                start = i + 1;
                index++;
            }
        }
        return parts;
    }

    function splitDomainOnlyAssembly(string memory domainName) internal pure returns (string[] memory) {
        string[] memory parts;
        assembly {
            let count := 1
            let domainPtr := add(domainName, 0x20) 
            let endPtr := add(domainPtr, mload(domainName)) 
            for {
                let currPtr := domainPtr
            } lt(currPtr, endPtr) {
                currPtr := add(currPtr, 1)
            } {
                if eq(byte(0, mload(currPtr)), 0x2e) {
                    
                    count := add(count, 1)
                }
            }

            parts := msize() 
            mstore(parts, count) 
            let partsData := add(parts, 0x20) 

            let start := domainPtr
            let index := 0

            for {
                let currPtr := domainPtr
            } lt(currPtr, endPtr) {
                currPtr := add(currPtr, 1)
            } {
                if or(
                    eq(byte(0, mload(currPtr)), 0x2e),
                    eq(add(currPtr, 1), endPtr)
                ) {
                    
                    let length := sub(currPtr, start)
                    if eq(add(currPtr, 1), endPtr) {
                        length := add(length, 1)
                    }
                    mstore(add(partsData, mul(index, 0x20)), length)
                    for {
                        let i := 0
                    } lt(i, length) {
                        i := add(i, 1)
                    } {
                        mstore8(
                            add(add(partsData, mul(index, 0x20)), add(i, 0x20)),
                            byte(0, mload(add(start, i)))
                        )
                    }
                    start := add(currPtr, 1)
                    index := add(index, 1)
                }
            }
        }
        return parts;
    }

    
    function getParentDomain(string memory domainName) internal pure returns (string memory) {
        string[] memory parts = splitDomain(domainName);
        if (parts.length <= 2) {
            return "";
        }

        string memory parentDomain = parts[1];
        for (uint i = 2; i < parts.length; i++) {
            parentDomain = string(
                abi.encodePacked(parentDomain, ".", parts[i])
            );
        }
        return parentDomain;
    }

    function getParentDomainAssembly(string memory domainName) internal pure returns (string memory) {
        string[] memory parts = splitDomainOnlyAssembly(domainName);
        if (parts.length <= 2) {
            return "";
        }

        string memory parentDomain = parts[1];
        for (uint i = 2; i < parts.length; i++) {
            parentDomain = string(
                abi.encodePacked(parentDomain, ".", parts[i])
            );
        }
        return parentDomain;
    }

    function isValidDomainCharacter(bytes1 char) internal pure returns (bool) {
        return
            (char >= "a" && char <= "z") ||
            (char >= "0" && char <= "9") ||
            (char == "-");
    }

    function isValidDomain(string memory domainName) internal pure returns (bool) {
        bytes memory domainBytes = bytes(domainName);
        if (
            domainBytes.length == 0 ||
            domainBytes[0] == "." ||
            domainBytes[domainBytes.length - 1] == "."
        ) {
            return false;
        }
        bool dotFound = false;
        for (uint i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == ".") {
                dotFound = true;
                continue;
            }
            if (!isValidDomainCharacter(domainBytes[i])) {
                return false;
            }
        }

        return dotFound;
    }

}

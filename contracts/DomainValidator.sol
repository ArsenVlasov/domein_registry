// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library DomainValidator {
    function stripProtocol(string memory domainName) internal pure returns (string memory) {
        bytes memory domainBytes = bytes(domainName);

        if (domainBytes.length < 8) {
            return domainName;
        }
        if (domainBytes[5] == ':' && domainBytes[6] == '/' && domainBytes[7] == '/')  {
            bytes memory strippedBytes = new bytes(domainBytes.length - 8);
            for (uint i = 8; i < domainBytes.length; i++) {
                strippedBytes[i - 8] = domainBytes[i];
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
                if (i > 0 && domainBytes[i - 1] == ".") {
                    // Two consecutive dots found
                    return false;
                }
                dotFound = true;
                continue;
            }
            if (!isValidDomainCharacter(domainBytes[i])) {
                return false;
            }
        }
        return dotFound;
    }


    // function isValidDomain(string memory domainName) internal pure returns (bool) {
    //     assembly {
    //         let domainBytes := add(domainName, 0x20)
    //         let end := add(domainBytes, mload(domainName))
            
    //         if iszero(mload(domainName)) {
    //             mstore(0x00, 0)
    //             return(0x00, 0x20)
    //         }
    //         if or(eq(byte(0, mload(domainBytes)), "."), eq(byte(0, mload(sub(end, 1))), ".")) {
    //             mstore(0x00, 0)
    //             return(0x00, 0x20)
    //         }

    //         let dotFound := 0
    //         let lastChar := byte(0, mload(domainBytes))
            
    //         for { let i := add(domainBytes, 1) } lt(i, end) { i := add(i, 1) } {
    //             if and(eq(byte(0, mload(i)), "."), eq(lastChar, ".")) {
    //                 mstore(0x00, 0)
    //                 return(0x00, 0x20)
    //             }

    //             if eq(byte(0, mload(i)), ".") {
    //                 dotFound := 1
    //                 lastChar := byte(0, mload(i))
    //                 continue
    //             }
    //             let charCode := byte(0, mload(i))
    //             let conditionA := and(iszero(slt(sub(charCode, 65), 0)), iszero(slt(sub(90, charCode), 0)))
    //             let conditionB := and(iszero(slt(sub(charCode, 97), 0)), iszero(slt(sub(122, charCode), 0)))
    //             let conditionC := and(iszero(slt(sub(charCode, 48), 0)), iszero(slt(sub(57, charCode), 0)))
    //             let conditionD := eq(charCode, 45)

    //             if or(or(conditionA, conditionB), or(conditionC, conditionD)) {
    //                 mstore(0x00, 0)
    //                 return(0x00, 0x20)
    //             }
    //         }

    //         if iszero(dotFound) {
    //             mstore(0x00, 0)
    //             return(0x00, 0x20)
    //         }
    //         mstore(0x00, 1)
    //         return(0x00, 0x20)
    //     }
    // }

}


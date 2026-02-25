// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ScaleEncoder
 * @notice Library for encoding Solidity types into SCALE byte format
 * @dev SCALE (Simple Concatenated Aggregate Little-Endian) codec implementation
 * Reference: https://docs.substrate.io/reference/scale-codec/
 */
library ScaleEncoder {
    /**
     * @notice Encode a uint8 value
     * @param value The value to encode
     * @return Encoded bytes in little-endian format
     */
    function encodeU8(uint8 value) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = bytes1(value);
        return encoded;
    }

    /**
     * @notice Encode a uint32 value in little-endian format
     * @param value The value to encode
     * @return Encoded bytes (4 bytes)
     */
    function encodeU32(uint32 value) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(4);
        encoded[0] = bytes1(uint8(value));
        encoded[1] = bytes1(uint8(value >> 8));
        encoded[2] = bytes1(uint8(value >> 16));
        encoded[3] = bytes1(uint8(value >> 24));
        return encoded;
    }

    /**
     * @notice Encode a uint64 value in little-endian format
     * @param value The value to encode
     * @return Encoded bytes (8 bytes)
     */
    function encodeU64(uint64 value) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(8);
        for (uint256 i = 0; i < 8; i++) {
            encoded[i] = bytes1(uint8(value >> (i * 8)));
        }
        return encoded;
    }

    /**
     * @notice Encode a uint128 value in little-endian format
     * @param value The value to encode
     * @return Encoded bytes (16 bytes)
     */
    function encodeU128(uint128 value) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(16);
        for (uint256 i = 0; i < 16; i++) {
            encoded[i] = bytes1(uint8(value >> (i * 8)));
        }
        return encoded;
    }

    /**
     * @notice Encode a compact integer (variable-length encoding)
     * @dev Compact encoding rules:
     * - 0-63: single byte mode (00)
     * - 64-16383: two-byte mode (01)
     * - 16384-1073741823: four-byte mode (10)
     * - Larger: big-integer mode (11)
     * @param value The value to encode
     * @return Encoded bytes in compact format
     */
    function encodeCompact(uint256 value) internal pure returns (bytes memory) {
        if (value < 64) {
            // Single byte mode
            return abi.encodePacked(uint8(value << 2));
        } else if (value < 16384) {
            // Two-byte mode
            uint16 v = uint16(value << 2) | 1;
            bytes memory encoded = new bytes(2);
            encoded[0] = bytes1(uint8(v));
            encoded[1] = bytes1(uint8(v >> 8));
            return encoded;
        } else if (value < 1073741824) {
            // Four-byte mode
            uint32 v = uint32(value << 2) | 2;
            return encodeU32(v);
        } else {
            // Big-integer mode
            uint256 numBytes = 0;
            uint256 temp = value;
            while (temp > 0) {
                numBytes++;
                temp >>= 8;
            }

            bytes memory encoded = new bytes(numBytes + 1);
            encoded[0] = bytes1(uint8(((numBytes - 4) << 2) | 3));

            for (uint256 i = 0; i < numBytes; i++) {
                encoded[i + 1] = bytes1(uint8(value >> (i * 8)));
            }
            return encoded;
        }
    }

    /**
     * @notice Encode a bytes array with length prefix
     * @param data The bytes to encode
     * @return Encoded bytes with compact length prefix
     */
    function encodeBytes(bytes memory data) internal pure returns (bytes memory) {
        bytes memory length = encodeCompact(data.length);
        return abi.encodePacked(length, data);
    }

    /**
     * @notice Encode a string with length prefix
     * @param str The string to encode
     * @return Encoded bytes
     */
    function encodeString(string memory str) internal pure returns (bytes memory) {
        return encodeBytes(bytes(str));
    }

    /**
     * @notice Encode a MultiLocation structure
     * @param parents Number of parent hops
     * @param interior Encoded interior junctions
     * @return Encoded MultiLocation
     */
    function encodeMultiLocation(uint8 parents, bytes memory interior)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(encodeU8(parents), interior);
    }

    /**
     * @notice Concatenate multiple byte arrays
     * @param parts Array of byte arrays to concatenate
     * @return Concatenated bytes
     */
    function concat(bytes[] memory parts) internal pure returns (bytes memory) {
        uint256 totalLength = 0;
        for (uint256 i = 0; i < parts.length; i++) {
            totalLength += parts[i].length;
        }

        bytes memory result = new bytes(totalLength);
        uint256 offset = 0;

        for (uint256 i = 0; i < parts.length; i++) {
            bytes memory part = parts[i];
            for (uint256 j = 0; j < part.length; j++) {
                result[offset + j] = part[j];
            }
            offset += part.length;
        }

        return result;
    }
}

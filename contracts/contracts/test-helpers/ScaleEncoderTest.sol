// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../libs/ScaleEncoder.sol";

/**
 * @title ScaleEncoderTest
 * @notice Test helper contract that exposes ScaleEncoder library functions
 * @dev Only used for testing - not part of production deployment
 */
contract ScaleEncoderTest {
    using ScaleEncoder for *;

    function testEncodeU8(uint8 value) external pure returns (bytes memory) {
        return ScaleEncoder.encodeU8(value);
    }

    function testEncodeU32(uint32 value) external pure returns (bytes memory) {
        return ScaleEncoder.encodeU32(value);
    }

    function testEncodeU64(uint64 value) external pure returns (bytes memory) {
        return ScaleEncoder.encodeU64(value);
    }

    function testEncodeU128(uint128 value) external pure returns (bytes memory) {
        return ScaleEncoder.encodeU128(value);
    }

    function testEncodeCompact(uint256 value) external pure returns (bytes memory) {
        return ScaleEncoder.encodeCompact(value);
    }

    function testEncodeBytes(bytes memory data) external pure returns (bytes memory) {
        return ScaleEncoder.encodeBytes(data);
    }

    function testEncodeString(string memory str) external pure returns (bytes memory) {
        return ScaleEncoder.encodeString(str);
    }

    function testEncodeMultiLocation(uint8 parents, bytes memory interior)
        external
        pure
        returns (bytes memory)
    {
        return ScaleEncoder.encodeMultiLocation(parents, interior);
    }

    function testConcat(bytes[] memory parts) external pure returns (bytes memory) {
        return ScaleEncoder.concat(parts);
    }
}

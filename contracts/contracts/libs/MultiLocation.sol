// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ScaleEncoder.sol";

/**
 * @title MultiLocation
 * @notice Library for constructing XCM MultiLocation structures
 * @dev MultiLocation represents a location in the XCM multiverse
 */
library MultiLocation {
    using ScaleEncoder for *;

    /**
     * @notice Destination parachain IDs
     */
    uint32 constant ASSET_HUB = 1000;
    uint32 constant BRIDGE_HUB = 1002;
    uint32 constant ACALA = 2000;
    uint32 constant MOONBEAM = 2004;
    uint32 constant ASTAR = 2006;
    uint32 constant BIFROST = 2030;
    uint32 constant HYDRATION = 2034;

    /**
     * @notice Build a MultiLocation pointing to a parachain
     * @dev Constructs: { parents: 1, interior: X1(Parachain(id)) }
     * @param paraId Parachain ID
     * @return Encoded MultiLocation bytes
     */
    function parachain(uint32 paraId) internal pure returns (bytes memory) {
        // parents = 1
        bytes memory parents = ScaleEncoder.encodeU8(1);

        // interior = X1(Parachain(paraId))
        // X1 variant = 0x01
        // Parachain variant = 0x00
        bytes memory interior = abi.encodePacked(
            hex"01",  // X1
            hex"00",  // Parachain variant
            ScaleEncoder.encodeCompact(paraId)
        );

        return abi.encodePacked(parents, interior);
    }

    /**
     * @notice Build a MultiLocation pointing to an AccountId32
     * @dev Constructs: { parents: 0, interior: X1(AccountId32(id, network: None)) }
     * @param accountId 32-byte account ID
     * @return Encoded MultiLocation bytes
     */
    function accountId32(bytes32 accountId) internal pure returns (bytes memory) {
        // parents = 0
        bytes memory parents = ScaleEncoder.encodeU8(0);

        // interior = X1(AccountId32(id, network: None))
        // X1 variant = 0x01
        // AccountId32 variant = 0x01
        // network = None (0x00)
        bytes memory interior = abi.encodePacked(
            hex"01",  // X1
            hex"01",  // AccountId32 variant
            accountId,
            hex"00"   // network: None
        );

        return abi.encodePacked(parents, interior);
    }

    /**
     * @notice Build a MultiLocation pointing to an AccountKey20 (EVM address)
     * @dev Constructs: { parents: 0, interior: X1(AccountKey20(addr, network: None)) }
     * @param addr 20-byte EVM address
     * @return Encoded MultiLocation bytes
     */
    function accountKey20(address addr) internal pure returns (bytes memory) {
        // parents = 0
        bytes memory parents = ScaleEncoder.encodeU8(0);

        // interior = X1(AccountKey20(addr, network: None))
        // X1 variant = 0x01
        // AccountKey20 variant = 0x03
        // network = None (0x00)
        bytes memory interior = abi.encodePacked(
            hex"01",  // X1
            hex"03",  // AccountKey20 variant
            addr,
            hex"00"   // network: None
        );

        return abi.encodePacked(parents, interior);
    }

    /**
     * @notice Build a MultiLocation for a concrete fungible asset
     * @dev For native token on Polkadot Hub: { parents: 0, interior: Here }
     * @return Encoded MultiLocation bytes
     */
    function nativeAsset() internal pure returns (bytes memory) {
        // parents = 0
        bytes memory parents = ScaleEncoder.encodeU8(0);

        // interior = Here (0x00)
        bytes memory interior = hex"00";

        return abi.encodePacked(parents, interior);
    }

    /**
     * @notice Build a MultiLocation for an asset by ID
     * @dev Constructs: { parents: 0, interior: X2(PalletInstance(50), GeneralIndex(assetId)) }
     * @param assetId Asset ID
     * @return Encoded MultiLocation bytes
     */
    function assetById(uint128 assetId) internal pure returns (bytes memory) {
        // parents = 0
        bytes memory parents = ScaleEncoder.encodeU8(0);

        // interior = X2(PalletInstance(50), GeneralIndex(assetId))
        // X2 variant = 0x02
        // PalletInstance variant = 0x04
        // GeneralIndex variant = 0x07
        bytes memory interior = abi.encodePacked(
            hex"02",  // X2
            hex"04",  // PalletInstance variant
            hex"32",  // pallet index 50 (assets pallet)
            hex"07",  // GeneralIndex variant
            ScaleEncoder.encodeU128(assetId)
        );

        return abi.encodePacked(parents, interior);
    }

    /**
     * @notice Build a MultiLocation for ERC20 token on current chain
     * @dev Maps EVM address to asset location
     * @param token Token address
     * @return Encoded MultiLocation bytes for the asset
     */
    function assetLocation(address token) internal pure returns (bytes memory) {
        // For now, we use a simplified mapping
        // In production, this would query a registry or use a specific encoding
        // This is placeholder logic - actual implementation depends on Hub's asset system
        return nativeAsset();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../libs/MultiLocation.sol";

/**
 * @title MultiLocationTest
 * @notice Test helper contract that exposes MultiLocation library functions
 * @dev Only used for testing - not part of production deployment
 */
contract MultiLocationTest {
    using MultiLocation for *;

    // Expose constants
    uint32 public constant ASSET_HUB = MultiLocation.ASSET_HUB;
    uint32 public constant BRIDGE_HUB = MultiLocation.BRIDGE_HUB;
    uint32 public constant HYDRATION = MultiLocation.HYDRATION;
    uint32 public constant MOONBEAM = MultiLocation.MOONBEAM;
    uint32 public constant ASTAR = MultiLocation.ASTAR;
    uint32 public constant ACALA = MultiLocation.ACALA;
    uint32 public constant BIFROST = MultiLocation.BIFROST;

    function testParachain(uint32 paraId) external pure returns (bytes memory) {
        return MultiLocation.parachain(paraId);
    }

    function testAccountId32(bytes32 accountId) external pure returns (bytes memory) {
        return MultiLocation.accountId32(accountId);
    }

    function testAccountKey20(address account) external pure returns (bytes memory) {
        return MultiLocation.accountKey20(account);
    }

    function testNativeAsset() external pure returns (bytes memory) {
        return MultiLocation.nativeAsset();
    }

    function testAssetById(uint128 assetId) external pure returns (bytes memory) {
        return MultiLocation.assetById(assetId);
    }

    function testAssetLocation(address token) external pure returns (bytes memory) {
        return MultiLocation.assetLocation(token);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ScaleEncoder.sol";
import "./MultiLocation.sol";

/**
 * @title XCMProgram
 * @notice Library for assembling XCM instruction sequences
 * @dev Builds complete XCM programs from individual instructions
 */
library XCMProgram {
    using ScaleEncoder for *;

    /**
     * @notice XCM instruction opcodes (V3/V4/V5 compatible)
     */
    uint8 constant WITHDRAW_ASSET = 0x04;
    uint8 constant RESERVE_ASSET_DEPOSITED = 0x05;
    uint8 constant CLEAR_ORIGIN = 0x0D;
    uint8 constant BUY_EXECUTION = 0x08;
    uint8 constant DEPOSIT_ASSET = 0x12;
    uint8 constant TRANSFER_ASSET = 0x15;
    uint8 constant TELEPORT_ASSET = 0x03;
    uint8 constant EXCHANGE_ASSET = 0x16;

    /**
     * @notice Build a WithdrawAsset instruction
     * @dev Withdraws assets from the origin account
     * @param assetLocation MultiLocation of the asset
     * @param amount Amount to withdraw
     * @return Encoded instruction
     */
    function withdrawAsset(bytes memory assetLocation, uint128 amount)
        internal
        pure
        returns (bytes memory)
    {
        // VersionedAssets: V3
        bytes memory fungibility = abi.encodePacked(
            hex"00",  // Fungible variant
            ScaleEncoder.encodeCompact(amount)
        );

        bytes memory asset = abi.encodePacked(
            hex"00",  // Concrete variant
            assetLocation,
            fungibility
        );

        // Assets vec with length 1
        bytes memory assets = abi.encodePacked(
            ScaleEncoder.encodeCompact(1),
            asset
        );

        return abi.encodePacked(
            ScaleEncoder.encodeU8(WITHDRAW_ASSET),
            assets
        );
    }

    /**
     * @notice Build a ClearOrigin instruction
     * @dev Clears the origin, making subsequent instructions trustless
     * @return Encoded instruction
     */
    function clearOrigin() internal pure returns (bytes memory) {
        return abi.encodePacked(ScaleEncoder.encodeU8(CLEAR_ORIGIN));
    }

    /**
     * @notice Build a BuyExecution instruction
     * @dev Pays for execution on the destination chain
     * @param assetLocation MultiLocation of the fee asset
     * @param feeAmount Amount to pay for execution
     * @return Encoded instruction
     */
    function buyExecution(bytes memory assetLocation, uint128 feeAmount)
        internal
        pure
        returns (bytes memory)
    {
        // Fee asset
        bytes memory fungibility = abi.encodePacked(
            hex"00",  // Fungible variant
            ScaleEncoder.encodeCompact(feeAmount)
        );

        bytes memory feeAsset = abi.encodePacked(
            hex"00",  // Concrete variant
            assetLocation,
            fungibility
        );

        // WeightLimit: Unlimited (0x00)
        bytes memory weightLimit = hex"00";

        return abi.encodePacked(
            ScaleEncoder.encodeU8(BUY_EXECUTION),
            feeAsset,
            weightLimit
        );
    }

    /**
     * @notice Build a DepositAsset instruction
     * @dev Deposits assets to a beneficiary
     * @param beneficiary MultiLocation of the recipient
     * @return Encoded instruction
     */
    function depositAsset(bytes memory beneficiary)
        internal
        pure
        returns (bytes memory)
    {
        // AssetFilter: Wild(All) - deposit all assets
        bytes memory assetFilter = hex"01";  // Wild variant, All

        return abi.encodePacked(
            ScaleEncoder.encodeU8(DEPOSIT_ASSET),
            assetFilter,
            beneficiary
        );
    }

    /**
     * @notice Build a complete reserve transfer XCM program
     * @dev Standard sequence: WithdrawAsset -> ClearOrigin -> BuyExecution -> DepositAsset
     * @param assetLocation MultiLocation of the asset to transfer
     * @param amount Amount to transfer
     * @param feeAmount Amount for execution fees
     * @param beneficiary Recipient MultiLocation
     * @return Complete encoded XCM program
     */
    function buildReserveTransfer(
        bytes memory assetLocation,
        uint128 amount,
        uint128 feeAmount,
        bytes memory beneficiary
    ) internal pure returns (bytes memory) {
        // Build instruction sequence
        bytes memory inst1 = withdrawAsset(assetLocation, amount);
        bytes memory inst2 = clearOrigin();
        bytes memory inst3 = buyExecution(assetLocation, feeAmount);
        bytes memory inst4 = depositAsset(beneficiary);

        // Encode as vec of instructions (length = 4)
        bytes memory program = abi.encodePacked(
            ScaleEncoder.encodeCompact(4),
            inst1,
            inst2,
            inst3,
            inst4
        );

        // Wrap in XCM version (V3 = 0x03)
        return abi.encodePacked(hex"03", program);
    }

    /**
     * @notice Build a teleport transfer XCM program
     * @dev For trusted system chains (AssetHub, BridgeHub)
     * @param assetLocation MultiLocation of the asset
     * @param amount Amount to teleport
     * @param feeAmount Amount for execution fees
     * @param beneficiary Recipient MultiLocation
     * @return Complete encoded XCM program
     */
    function buildTeleport(
        bytes memory assetLocation,
        uint128 amount,
        uint128 feeAmount,
        bytes memory beneficiary
    ) internal pure returns (bytes memory) {
        // TeleportAsset instruction
        bytes memory fungibility = abi.encodePacked(
            hex"00",
            ScaleEncoder.encodeCompact(amount)
        );

        bytes memory asset = abi.encodePacked(
            hex"00",
            assetLocation,
            fungibility
        );

        bytes memory assets = abi.encodePacked(
            ScaleEncoder.encodeCompact(1),
            asset
        );

        bytes memory inst1 = abi.encodePacked(
            ScaleEncoder.encodeU8(TELEPORT_ASSET),
            assets,
            beneficiary
        );

        bytes memory inst2 = clearOrigin();
        bytes memory inst3 = buyExecution(assetLocation, feeAmount);
        bytes memory inst4 = depositAsset(beneficiary);

        bytes memory program = abi.encodePacked(
            ScaleEncoder.encodeCompact(4),
            inst1,
            inst2,
            inst3,
            inst4
        );

        return abi.encodePacked(hex"03", program);
    }
}

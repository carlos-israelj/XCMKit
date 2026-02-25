// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IXcm.sol";
import "./ScaleEncoder.sol";
import "./MultiLocation.sol";
import "./XCMProgram.sol";
import "./WeightHelper.sol";

/**
 * @title XCMKit
 * @notice Main library providing high-level XCM functionality
 * @dev Abstracts XCM precompile into developer-friendly functions
 */
library XCMKit {
    using ScaleEncoder for *;
    using MultiLocation for *;
    using XCMProgram for *;
    using WeightHelper for *;

    /**
     * @notice XCM precompile address
     */
    address constant XCM_PRECOMPILE = address(0xA0000);

    /**
     * @notice Events for XCM operations
     */
    event XCMTransferInitiated(
        uint32 indexed destinationParaId,
        address indexed recipient,
        address token,
        uint256 amount
    );

    event XCMMessageSent(bytes32 indexed messageId, bytes32 indexed destination);

    /**
     * @notice Transfer tokens to a destination parachain via reserve transfer
     * @param destinationParaId Parachain ID (use MultiLocation.HYDRATION etc.)
     * @param recipient Recipient address on the destination chain
     * @param token Token address on Polkadot Hub
     * @param amount Amount to transfer (in token decimals)
     */
    function transfer(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= type(uint128).max, "Amount too large");

        // Build MultiLocations
        bytes memory assetLocation = MultiLocation.assetLocation(token);
        bytes memory beneficiary = MultiLocation.accountKey20(recipient);

        // Estimate fee (10% of amount or minimum)
        uint128 feeAmount = uint128(amount / 10);
        if (feeAmount < 1000000) feeAmount = 1000000; // Minimum 0.001 units

        // Build XCM program
        bytes memory xcmProgram = XCMProgram.buildReserveTransfer(
            assetLocation,
            uint128(amount),
            feeAmount,
            beneficiary
        );

        // Execute XCM
        executeXCM(xcmProgram);
    }

    /**
     * @notice Transfer with explicit fee cap
     * @param destinationParaId Parachain ID
     * @param recipient Recipient address
     * @param token Token address
     * @param amount Amount to transfer
     * @param maxFee Maximum fee willing to pay
     */
    function transferWithFee(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount,
        uint256 maxFee
    ) internal {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= type(uint128).max, "Amount too large");
        require(maxFee <= type(uint128).max, "Fee too large");

        bytes memory assetLocation = MultiLocation.assetLocation(token);
        bytes memory beneficiary = MultiLocation.accountKey20(recipient);

        bytes memory xcmProgram = XCMProgram.buildReserveTransfer(
            assetLocation,
            uint128(amount),
            uint128(maxFee),
            beneficiary
        );

        executeXCM(xcmProgram);
    }

    /**
     * @notice Teleport for trusted system chains (AssetHub, BridgeHub)
     * @param destinationParaId Parachain ID
     * @param recipient Recipient address
     * @param token Token address
     * @param amount Amount to teleport
     */
    function teleport(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= type(uint128).max, "Amount too large");

        // Verify it's a system chain
        require(
            destinationParaId == MultiLocation.ASSET_HUB ||
            destinationParaId == MultiLocation.BRIDGE_HUB,
            "Teleport only allowed for system chains"
        );

        bytes memory assetLocation = MultiLocation.assetLocation(token);
        bytes memory beneficiary = MultiLocation.accountKey20(recipient);

        uint128 feeAmount = uint128(amount / 10);
        if (feeAmount < 1000000) feeAmount = 1000000;

        bytes memory xcmProgram = XCMProgram.buildTeleport(
            assetLocation,
            uint128(amount),
            feeAmount,
            beneficiary
        );

        executeXCM(xcmProgram);
    }

    /**
     * @notice Estimate the fee for a cross-chain transfer
     * @param destinationParaId Parachain ID
     * @param token Token address
     * @param amount Amount to transfer
     * @return weight Computed Weight struct (refTime, proofSize)
     * @return feePas Estimated fee in PAS (native token)
     */
    function estimateFee(
        uint32 destinationParaId,
        address token,
        uint256 amount
    ) internal view returns (IXcm.Weight memory weight, uint256 feePas) {
        require(amount <= type(uint128).max, "Amount too large");

        bytes memory assetLocation = MultiLocation.assetLocation(token);
        bytes memory beneficiary = MultiLocation.accountKey20(address(0)); // Dummy beneficiary

        uint128 feeAmount = uint128(amount / 10);
        if (feeAmount < 1000000) feeAmount = 1000000;

        bytes memory xcmProgram = XCMProgram.buildReserveTransfer(
            assetLocation,
            uint128(amount),
            feeAmount,
            beneficiary
        );

        weight = WeightHelper.weighMessage(xcmProgram);
        feePas = WeightHelper.estimateFee(xcmProgram);
    }

    /**
     * @notice Send an arbitrary XCM message to a destination
     * @param destinationParaId Destination parachain ID
     * @param message Encoded XCM message
     * @return messageId The ID of the sent message
     */
    function send(uint32 destinationParaId, bytes memory message)
        internal
        returns (bytes32 messageId)
    {
        bytes memory destination = MultiLocation.parachain(destinationParaId);
        IXcm xcm = IXcm(XCM_PRECOMPILE);
        messageId = xcm.send(destination, message);

        emit XCMMessageSent(messageId, keccak256(destination));
        return messageId;
    }

    /**
     * @notice Execute an XCM program locally
     * @param xcmProgram Encoded XCM program
     * @return success Whether execution succeeded
     */
    function execute(bytes memory xcmProgram) internal returns (bool success) {
        return executeXCM(xcmProgram);
    }

    /**
     * @notice Internal function to execute XCM
     * @param xcmProgram Encoded XCM program
     * @return success Whether execution succeeded
     */
    function executeXCM(bytes memory xcmProgram) private returns (bool) {
        // Get weight with 20% margin
        IXcm.Weight memory baseWeight = WeightHelper.weighMessage(xcmProgram);
        IXcm.Weight memory weight = WeightHelper.addMargin(baseWeight, 20);

        // Execute
        IXcm xcm = IXcm(XCM_PRECOMPILE);
        bytes memory outcome = xcm.execute(xcmProgram, weight);

        // Check outcome (simplified - actual outcome parsing TBD)
        return outcome.length > 0;
    }
}

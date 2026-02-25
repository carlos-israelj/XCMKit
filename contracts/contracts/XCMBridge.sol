// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./libs/XCMKit.sol";
import "./libs/MultiLocation.sol";
import "./interfaces/IXcm.sol";

/**
 * @title XCMBridge
 * @notice Coordinator contract for cross-chain transfers on Polkadot Hub
 * @dev User-facing contract that wraps XCMKit library functionality
 */
contract XCMBridge {
    using XCMKit for *;

    /**
     * @notice Events
     */
    event TransferInitiated(
        address indexed sender,
        uint32 indexed destinationParaId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 estimatedFee
    );

    event TeleportInitiated(
        address indexed sender,
        uint32 indexed destinationParaId,
        address indexed recipient,
        address token,
        uint256 amount
    );

    /**
     * @notice Transfer tokens to a destination parachain
     * @param destinationParaId Parachain ID (1000 = AssetHub, 2034 = Hydration, etc.)
     * @param recipient Recipient address on destination chain
     * @param token Token address on Polkadot Hub
     * @param amount Amount to transfer
     */
    function transfer(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) external {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");

        // Estimate fee for event
        (, uint256 fee) = XCMKit.estimateFee(destinationParaId, token, amount);

        // Execute transfer
        XCMKit.transfer(destinationParaId, recipient, token, amount);

        emit TransferInitiated(
            msg.sender,
            destinationParaId,
            recipient,
            token,
            amount,
            fee
        );
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
    ) external {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");

        XCMKit.transferWithFee(destinationParaId, recipient, token, amount, maxFee);

        emit TransferInitiated(
            msg.sender,
            destinationParaId,
            recipient,
            token,
            amount,
            maxFee
        );
    }

    /**
     * @notice Teleport tokens to trusted system chains
     * @param destinationParaId System chain ID (AssetHub or BridgeHub)
     * @param recipient Recipient address
     * @param token Token address
     * @param amount Amount to teleport
     */
    function teleport(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) external {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");

        XCMKit.teleport(destinationParaId, recipient, token, amount);

        emit TeleportInitiated(
            msg.sender,
            destinationParaId,
            recipient,
            token,
            amount
        );
    }

    /**
     * @notice Estimate fee for a cross-chain transfer
     * @param destinationParaId Parachain ID
     * @param token Token address
     * @param amount Amount to transfer
     * @return feePas Estimated fee in PAS
     */
    function estimateFee(
        uint32 destinationParaId,
        address token,
        uint256 amount
    ) external view returns (uint256 feePas) {
        (, feePas) = XCMKit.estimateFee(destinationParaId, token, amount);
    }

    /**
     * @notice Get weight for a transfer
     * @param destinationParaId Parachain ID
     * @param token Token address
     * @param amount Amount to transfer
     * @return weight Computed weight
     */
    function getTransferWeight(
        uint32 destinationParaId,
        address token,
        uint256 amount
    ) external view returns (IXcm.Weight memory weight) {
        (weight, ) = XCMKit.estimateFee(destinationParaId, token, amount);
    }

    /**
     * @notice Get supported destination chains
     * @return Array of supported parachain IDs
     */
    function getSupportedChains() external pure returns (uint32[] memory) {
        uint32[] memory chains = new uint32[](5);
        chains[0] = MultiLocation.ASSET_HUB;
        chains[1] = MultiLocation.HYDRATION;
        chains[2] = MultiLocation.MOONBEAM;
        chains[3] = MultiLocation.ASTAR;
        chains[4] = MultiLocation.BIFROST;
        return chains;
    }
}

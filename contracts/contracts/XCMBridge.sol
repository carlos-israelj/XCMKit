// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./libs/XCMKit.sol";
import "./interfaces/IXcm.sol";

/// @title XCMBridge — Demo coordinator for XCMKit playground
/// @notice Wraps XCMKit library functions as public contract functions
/// @dev Deployed on Passet Hub testnet. NOT for production use.
contract XCMBridge {

    // ─── State ────────────────────────────────────────────────────────────────

    address public owner;
    bool    private _locked;

    // ─── Events ───────────────────────────────────────────────────────────────

    event TransferInitiated(
        address indexed sender,
        uint32  indexed destinationParaId,
        address         recipient,
        address         token,
        uint256         amount
    );

    event FeeEstimated(
        uint32  indexed destinationParaId,
        uint64          refTime,
        uint64          proofSize,
        uint256         feePas
    );

    // ─── Errors ───────────────────────────────────────────────────────────────

    error NotOwner();
    error ReentrantCall();
    error ZeroAmount();
    error ZeroRecipient();

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier nonReentrant() {
        if (_locked) revert ReentrantCall();
        _locked = true;
        _;
        _locked = false;
    }

    // ─── Constructor ──────────────────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─── Public API (called by playground) ────────────────────────────────────

    /// @notice Execute a cross-chain reserve transfer via XCMKit
    /// @param destinationParaId Target parachain ID (use Destination.HYDRATION etc.)
    /// @param recipient Recipient address on destination chain
    /// @param token Token address on Polkadot Hub
    /// @param amount Amount in token decimals
    function transfer(
        uint32  destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) external nonReentrant {
        if (amount == 0)    revert ZeroAmount();
        if (recipient == address(0)) revert ZeroRecipient();

        XCMKit.transfer(destinationParaId, recipient, token, amount);

        emit TransferInitiated(msg.sender, destinationParaId, recipient, token, amount);
    }

    /// @notice Estimate fee for a transfer without executing it
    /// @return refTime Estimated computational weight
    /// @return proofSize Estimated proof size
    /// @return feePas Estimated fee in PAS (rough approximation)
    function estimateFee(
        uint32  destinationParaId,
        address token,
        uint256 amount
    ) external view returns (uint64 refTime, uint64 proofSize, uint256 feePas) {
        (IXcm.Weight memory w, uint256 fee) = XCMKit.estimateFee(
            destinationParaId, token, amount
        );
        return (w.refTime, w.proofSize, fee);
    }

    /// @notice Get list of supported destination chains
    /// @return Array of parachain IDs
    function getSupportedChains() external pure returns (uint32[] memory) {
        uint32[] memory chains = new uint32[](7);
        chains[0] = 1000; // ASSET_HUB
        chains[1] = 1002; // BRIDGE_HUB
        chains[2] = 2034; // HYDRATION
        chains[3] = 2004; // MOONBEAM
        chains[4] = 2006; // ASTAR
        chains[5] = 2000; // ACALA
        chains[6] = 2030; // BIFROST
        return chains;
    }
}

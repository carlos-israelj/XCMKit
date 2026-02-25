// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IXcm.sol";

/**
 * @title WeightHelper
 * @notice Library for XCM weight estimation and management
 * @dev Calls weighMessage on the XCM precompile
 */
library WeightHelper {
    /**
     * @notice XCM precompile address
     */
    address constant XCM_PRECOMPILE = 0x00000000000000000000000000000000000a0000;

    /**
     * @notice Default weight values for common operations
     */
    uint64 constant DEFAULT_REF_TIME = 1000000000;  // 1 billion
    uint64 constant DEFAULT_PROOF_SIZE = 65536;      // 64 KB

    /**
     * @notice Calculate the weight required for an XCM message
     * @param message Encoded XCM message
     * @return weight Computed weight struct
     */
    function weighMessage(bytes memory message)
        internal
        view
        returns (IXcm.Weight memory weight)
    {
        IXcm xcm = IXcm(XCM_PRECOMPILE);
        return xcm.weighMessage(message);
    }

    /**
     * @notice Estimate fees for a cross-chain transfer
     * @dev This is a simplified estimation - actual fees depend on destination chain
     * @param message Encoded XCM message
     * @return feePas Estimated fee in PAS (native token)
     */
    function estimateFee(bytes memory message)
        internal
        view
        returns (uint256 feePas)
    {
        IXcm.Weight memory weight = weighMessage(message);

        // Simplified fee calculation
        // In production, this should query fee multiplier from chain state
        // Fee = (refTime / 1e9) * base_fee + (proofSize / 1024) * byte_fee
        uint256 refTimeFee = (uint256(weight.refTime) * 100) / 1e9;  // 100 units per billion refTime
        uint256 proofSizeFee = (uint256(weight.proofSize) * 10) / 1024; // 10 units per KB

        return refTimeFee + proofSizeFee;
    }

    /**
     * @notice Create a default weight struct
     * @return weight Default weight
     */
    function defaultWeight() internal pure returns (IXcm.Weight memory weight) {
        weight.refTime = DEFAULT_REF_TIME;
        weight.proofSize = DEFAULT_PROOF_SIZE;
    }

    /**
     * @notice Create a custom weight struct
     * @param refTime Reference time
     * @param proofSize Proof size
     * @return weight Custom weight
     */
    function createWeight(uint64 refTime, uint64 proofSize)
        internal
        pure
        returns (IXcm.Weight memory weight)
    {
        weight.refTime = refTime;
        weight.proofSize = proofSize;
    }

    /**
     * @notice Add a safety margin to weight
     * @param weight Base weight
     * @param marginPercent Margin percentage (e.g., 10 for 10%)
     * @return Adjusted weight with margin
     */
    function addMargin(IXcm.Weight memory weight, uint256 marginPercent)
        internal
        pure
        returns (IXcm.Weight memory)
    {
        IXcm.Weight memory adjusted;
        adjusted.refTime = weight.refTime + uint64((uint256(weight.refTime) * marginPercent) / 100);
        adjusted.proofSize = weight.proofSize + uint64((uint256(weight.proofSize) * marginPercent) / 100);
        return adjusted;
    }
}

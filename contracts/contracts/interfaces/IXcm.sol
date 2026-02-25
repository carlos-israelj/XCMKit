// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IXcm
 * @notice Interface for the XCM precompile at 0x00000000000000000000000000000000000a0000
 * @dev Based on the official Polkadot SDK implementation
 * Source: https://github.com/paritytech/polkadot-sdk/blob/master/polkadot/xcm/pallet-xcm/src/precompiles/IXcm.sol
 */
interface IXcm {
    /**
     * @notice Weight struct for XCM message execution
     * @param refTime Reference time for execution
     * @param proofSize Size of the proof data
     */
    struct Weight {
        uint64 refTime;
        uint64 proofSize;
    }

    /**
     * @notice Execute an XCM message locally
     * @param message Encoded XCM message in SCALE format
     * @param maxWeight Maximum weight allowed for execution
     * @return outcome The execution outcome
     */
    function execute(bytes memory message, Weight memory maxWeight)
        external
        returns (bytes memory outcome);

    /**
     * @notice Send an XCM message to a destination
     * @param dest Encoded destination MultiLocation in SCALE format
     * @param message Encoded XCM message in SCALE format
     * @return messageId The ID of the sent message
     */
    function send(bytes memory dest, bytes memory message)
        external
        returns (bytes32 messageId);

    /**
     * @notice Calculate the weight required for an XCM message
     * @param message Encoded XCM message in SCALE format
     * @return weight The computed weight
     */
    function weighMessage(bytes memory message)
        external
        view
        returns (Weight memory weight);
}

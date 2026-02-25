// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../libs/XCMProgram.sol";

/**
 * @title XCMProgramTest
 * @notice Test helper contract that exposes XCMProgram library functions
 * @dev Only used for testing - not part of production deployment
 */
contract XCMProgramTest {
    using XCMProgram for *;

    function testWithdrawAsset(bytes memory assetLocation, uint128 amount)
        external
        pure
        returns (bytes memory)
    {
        return XCMProgram.withdrawAsset(assetLocation, amount);
    }

    function testClearOrigin() external pure returns (bytes memory) {
        return XCMProgram.clearOrigin();
    }

    function testBuyExecution(bytes memory assetLocation, uint128 feeAmount)
        external
        pure
        returns (bytes memory)
    {
        return XCMProgram.buyExecution(assetLocation, feeAmount);
    }

    function testDepositAsset(bytes memory beneficiary)
        external
        pure
        returns (bytes memory)
    {
        return XCMProgram.depositAsset(beneficiary);
    }

    function testBuildReserveTransfer(
        bytes memory assetLocation,
        uint128 amount,
        uint128 feeAmount,
        bytes memory beneficiary
    ) external pure returns (bytes memory) {
        return XCMProgram.buildReserveTransfer(
            assetLocation,
            amount,
            feeAmount,
            beneficiary
        );
    }

    function testBuildTeleport(
        bytes memory assetLocation,
        uint128 amount,
        uint128 feeAmount,
        bytes memory beneficiary
    ) external pure returns (bytes memory) {
        return XCMProgram.buildTeleport(
            assetLocation,
            amount,
            feeAmount,
            beneficiary
        );
    }
}

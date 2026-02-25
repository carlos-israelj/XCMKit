import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * Deployment module for XCMBridge contract
 *
 * Usage:
 * npx hardhat ignition deploy ./ignition/modules/XCMBridge.ts --network passetHubTestnet
 */
const XCMBridgeModule = buildModule("XCMBridgeModule", (m) => {
  // Deploy XCMBridge contract
  const xcmBridge = m.contract("XCMBridge", []);

  return { xcmBridge };
});

export default XCMBridgeModule;

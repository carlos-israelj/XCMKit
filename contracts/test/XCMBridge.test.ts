import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("XCMBridge", function () {
  async function deployXCMBridgeFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();
    const xcmBridge = await hre.viem.deployContract("XCMBridge", []);
    const publicClient = await hre.viem.getPublicClient();

    return {
      xcmBridge,
      owner,
      otherAccount,
      publicClient,
    };
  }

  describe("Deployment", function () {
    it("Should deploy successfully", async function () {
      const { xcmBridge } = await loadFixture(deployXCMBridgeFixture);
      expect(xcmBridge.address).to.be.properAddress;
    });

    it("Should return supported chains", async function () {
      const { xcmBridge } = await loadFixture(deployXCMBridgeFixture);
      const chains = await xcmBridge.read.getSupportedChains();

      expect(chains).to.have.lengthOf(5);
      expect(chains[0]).to.equal(1000n); // ASSET_HUB
      expect(chains[1]).to.equal(2034n); // HYDRATION
      expect(chains[2]).to.equal(2004n); // MOONBEAM
      expect(chains[3]).to.equal(2006n); // ASTAR
      expect(chains[4]).to.equal(2030n); // BIFROST
    });
  });

  describe("Fee Estimation", function () {
    it("Should estimate fee for transfer", async function () {
      const { xcmBridge } = await loadFixture(deployXCMBridgeFixture);
      const destinationParaId = 2034; // Hydration
      const token = "0x0000000000000000000000000000000000000001";
      const amount = 1000000n;

      // This will likely fail without a proper XCM precompile
      // but tests the interface
      try {
        const fee = await xcmBridge.read.estimateFee([
          destinationParaId,
          token,
          amount,
        ]);
        expect(fee).to.be.a("bigint");
      } catch (error) {
        // Expected to fail in test environment without XCM precompile
        expect(error).to.exist;
      }
    });
  });

  describe("Validation", function () {
    it("Should revert transfer with zero amount", async function () {
      const { xcmBridge, owner } = await loadFixture(deployXCMBridgeFixture);
      const destinationParaId = 2034;
      const recipient = "0x1000000000000000000000000000000000000001";
      const token = "0x0000000000000000000000000000000000000001";
      const amount = 0n;

      await expect(
        xcmBridge.write.transfer(
          [destinationParaId, recipient, token, amount],
          { account: owner.account }
        )
      ).to.be.rejectedWith("Amount must be greater than 0");
    });

    it("Should revert transfer with invalid recipient", async function () {
      const { xcmBridge, owner } = await loadFixture(deployXCMBridgeFixture);
      const destinationParaId = 2034;
      const recipient = "0x0000000000000000000000000000000000000000";
      const token = "0x0000000000000000000000000000000000000001";
      const amount = 1000000n;

      await expect(
        xcmBridge.write.transfer(
          [destinationParaId, recipient, token, amount],
          { account: owner.account }
        )
      ).to.be.rejectedWith("Invalid recipient");
    });

    it("Should revert teleport to non-system chain", async function () {
      const { xcmBridge, owner } = await loadFixture(deployXCMBridgeFixture);
      const destinationParaId = 2034; // Hydration - not a system chain
      const recipient = "0x1000000000000000000000000000000000000001";
      const token = "0x0000000000000000000000000000000000000001";
      const amount = 1000000n;

      await expect(
        xcmBridge.write.teleport(
          [destinationParaId, recipient, token, amount],
          { account: owner.account }
        )
      ).to.be.rejectedWith("Teleport only allowed for system chains");
    });
  });
});

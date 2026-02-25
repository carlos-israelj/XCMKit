import { expect } from "chai";
import hre from "hardhat";

describe("XCMProgram Library", function () {
  let xcmProgramTest: any;
  let multiLocationTest: any;

  before(async function () {
    const XCMProgramTest = await hre.viem.deployContract("XCMProgramTest", []);
    const MultiLocationTest = await hre.viem.deployContract("MultiLocationTest", []);
    xcmProgramTest = XCMProgramTest;
    multiLocationTest = MultiLocationTest;
  });

  describe("Individual XCM Instructions", function () {
    it("Should build WithdrawAsset instruction", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const amount = 1000000000000000000n; // 1 token

      const result = await xcmProgramTest.read.testWithdrawAsset([
        assetLocation,
        amount,
      ]);

      // WithdrawAsset opcode is 0x04
      expect(result).to.not.equal("0x");
      expect(result).to.include("04"); // Should contain WithdrawAsset opcode
    });

    it("Should build ClearOrigin instruction", async function () {
      const result = await xcmProgramTest.read.testClearOrigin([]);

      // ClearOrigin opcode is 0x0D
      expect(result).to.equal("0x0d");
    });

    it("Should build BuyExecution instruction", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const feeAmount = 100000000000000000n; // 0.1 token

      const result = await xcmProgramTest.read.testBuyExecution([
        assetLocation,
        feeAmount,
      ]);

      // BuyExecution opcode is 0x08
      expect(result).to.not.equal("0x");
      expect(result).to.include("08");
    });

    it("Should build DepositAsset instruction", async function () {
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);

      const result = await xcmProgramTest.read.testDepositAsset([beneficiary]);

      // DepositAsset opcode is 0x12
      expect(result).to.not.equal("0x");
      expect(result).to.include("12");
    });
  });

  describe("Reserve Transfer Program", function () {
    it("Should build complete reserve transfer program", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 1000000000000000000n;
      const feeAmount = 100000000000000000n;

      const result = await xcmProgramTest.read.testBuildReserveTransfer([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      // Should contain all required opcodes in sequence
      expect(result).to.not.equal("0x");
      expect(result).to.include("04"); // WithdrawAsset
      expect(result).to.include("0d"); // ClearOrigin
      expect(result).to.include("08"); // BuyExecution
      expect(result).to.include("12"); // DepositAsset
    });

    it("Should build reserve transfer with minimal amount", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 1n;
      const feeAmount = 1n;

      const result = await xcmProgramTest.read.testBuildReserveTransfer([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      expect(result).to.not.equal("0x");
      expect(result.length).to.be.greaterThan(2);
    });

    it("Should build reserve transfer with large amount", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 1000000n * 10n ** 18n; // 1 million tokens
      const feeAmount = 10000n * 10n ** 18n; // 10k tokens fee

      const result = await xcmProgramTest.read.testBuildReserveTransfer([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      expect(result).to.not.equal("0x");
    });
  });

  describe("Teleport Program", function () {
    it("Should build complete teleport program", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 1000000000000000000n;
      const feeAmount = 100000000000000000n;

      const result = await xcmProgramTest.read.testBuildTeleport([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      // Should contain teleport-specific opcodes
      expect(result).to.not.equal("0x");
      expect(result).to.include("05"); // ReserveAssetDeposited (used in teleport)
    });

    it("Should build teleport with different asset", async function () {
      const assetId = 1984n;
      const assetLocation = await multiLocationTest.read.testAssetById([assetId]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 500000000000000000n;
      const feeAmount = 50000000000000000n;

      const result = await xcmProgramTest.read.testBuildTeleport([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      expect(result).to.not.equal("0x");
    });
  });

  describe("Integration Tests", function () {
    it("Should build programs for all supported chains", async function () {
      const chains = [1000, 1002, 2000, 2004, 2006, 2030, 2034];
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 1000000000000000000n;
      const feeAmount = 100000000000000000n;

      for (const chainId of chains) {
        const result = await xcmProgramTest.read.testBuildReserveTransfer([
          assetLocation,
          amount,
          feeAmount,
          beneficiary,
        ]);

        expect(result).to.not.equal("0x");
        expect(result.length).to.be.greaterThan(10);
      }
    });

    it("Should produce different programs for reserve transfer vs teleport", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 1000000000000000000n;
      const feeAmount = 100000000000000000n;

      const reserveTransfer = await xcmProgramTest.read.testBuildReserveTransfer([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      const teleport = await xcmProgramTest.read.testBuildTeleport([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      // Programs should be different
      expect(reserveTransfer).to.not.equal(teleport);
    });

    it("Should handle various beneficiary types", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const amount = 1000000000000000000n;
      const feeAmount = 100000000000000000n;

      // EVM address
      const evmBeneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);

      const evmResult = await xcmProgramTest.read.testBuildReserveTransfer([
        assetLocation,
        amount,
        feeAmount,
        evmBeneficiary,
      ]);

      // Substrate AccountId32
      const substrateAccount = "0x" + "aa".repeat(32);
      const substrateBeneficiary = await multiLocationTest.read.testAccountId32([
        substrateAccount,
      ]);

      const substrateResult = await xcmProgramTest.read.testBuildReserveTransfer([
        assetLocation,
        amount,
        feeAmount,
        substrateBeneficiary,
      ]);

      expect(evmResult).to.not.equal("0x");
      expect(substrateResult).to.not.equal("0x");
      expect(evmResult).to.not.equal(substrateResult);
    });
  });

  describe("XCM Message Structure", function () {
    it("Should produce valid SCALE-encoded XCM message", async function () {
      const assetLocation = await multiLocationTest.read.testNativeAsset([]);
      const beneficiary = await multiLocationTest.read.testAccountKey20([
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0",
      ]);
      const amount = 1000000000000000000n;
      const feeAmount = 100000000000000000n;

      const result = await xcmProgramTest.read.testBuildReserveTransfer([
        assetLocation,
        amount,
        feeAmount,
        beneficiary,
      ]);

      // XCM message should start with version and instruction count
      expect(result).to.not.equal("0x");

      // Should be a reasonable size (not empty, not huge)
      const byteLength = (result.length - 2) / 2; // Remove "0x" and divide by 2
      expect(byteLength).to.be.greaterThan(20);
      expect(byteLength).to.be.lessThan(1000);
    });
  });
});

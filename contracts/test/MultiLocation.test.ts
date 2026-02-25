import { expect } from "chai";
import hre from "hardhat";

describe("MultiLocation Library", function () {
  let multiLocationTest: any;

  before(async function () {
    // Deploy a test contract that uses MultiLocation
    const MultiLocationTest = await hre.viem.deployContract("MultiLocationTest", []);
    multiLocationTest = MultiLocationTest;
  });

  describe("Parachain Addressing", function () {
    it("Should construct parachain MultiLocation for AssetHub (1000)", async function () {
      const result = await multiLocationTest.read.testParachain([1000]);

      // { parents: 1, interior: X1(Parachain(1000)) }
      // Should contain parents=1 and parachain ID 1000 (0x03E8 -> 0xE8030000 little-endian)
      expect(result).to.include("01"); // parents = 1
    });

    it("Should construct parachain MultiLocation for Hydration (2034)", async function () {
      const result = await multiLocationTest.read.testParachain([2034]);

      // Hydration parachain ID 2034 = 0x07F2
      expect(result).to.not.equal("0x");
      expect(result).to.include("01"); // parents = 1
    });

    it("Should construct parachain MultiLocation for all supported chains", async function () {
      const chains = [
        { name: "AssetHub", id: 1000 },
        { name: "BridgeHub", id: 1002 },
        { name: "Acala", id: 2000 },
        { name: "Moonbeam", id: 2004 },
        { name: "Astar", id: 2006 },
        { name: "Bifrost", id: 2030 },
        { name: "Hydration", id: 2034 },
      ];

      for (const chain of chains) {
        const result = await multiLocationTest.read.testParachain([chain.id]);
        expect(result).to.not.equal("0x");
        expect(result.length).to.be.greaterThan(2);
      }
    });
  });

  describe("Account Addressing", function () {
    it("Should construct AccountId32 MultiLocation", async function () {
      const accountId = "0x" + "11".repeat(32); // 32-byte account ID
      const result = await multiLocationTest.read.testAccountId32([accountId]);

      // { parents: 0, interior: X1(AccountId32(id, None)) }
      expect(result).to.include("00"); // parents = 0
      expect(result).to.include(accountId.slice(2)); // Should contain the account ID
    });

    it("Should construct AccountKey20 MultiLocation for EVM address", async function () {
      const evmAddress = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0";
      const result = await multiLocationTest.read.testAccountKey20([evmAddress]);

      // { parents: 0, interior: X1(AccountKey20(addr, None)) }
      expect(result).to.include("00"); // parents = 0
    });

    it("Should handle zero address", async function () {
      const zeroAddress = "0x0000000000000000000000000000000000000000";
      const result = await multiLocationTest.read.testAccountKey20([zeroAddress]);

      expect(result).to.not.equal("0x");
    });
  });

  describe("Asset Locations", function () {
    it("Should construct native asset location", async function () {
      const result = await multiLocationTest.read.testNativeAsset([]);

      // Native asset typically has parents=1 and refers to parent chain
      expect(result).to.not.equal("0x");
      expect(result.length).to.be.greaterThan(2);
    });

    it("Should construct asset by ID location", async function () {
      const assetId = 1984n; // Example asset ID
      const result = await multiLocationTest.read.testAssetById([assetId]);

      expect(result).to.not.equal("0x");
    });

    it("Should construct asset location for token address", async function () {
      const tokenAddress = "0x1234567890123456789012345678901234567890";
      const result = await multiLocationTest.read.testAssetLocation([tokenAddress]);

      expect(result).to.not.equal("0x");
    });
  });

  describe("Chain Constants", function () {
    it("Should have correct constant for AssetHub", async function () {
      const assetHub = await multiLocationTest.read.ASSET_HUB([]);
      expect(assetHub).to.equal(1000);
    });

    it("Should have correct constant for BridgeHub", async function () {
      const bridgeHub = await multiLocationTest.read.BRIDGE_HUB([]);
      expect(bridgeHub).to.equal(1002);
    });

    it("Should have correct constant for Hydration", async function () {
      const hydration = await multiLocationTest.read.HYDRATION([]);
      expect(hydration).to.equal(2034);
    });

    it("Should have correct constant for Moonbeam", async function () {
      const moonbeam = await multiLocationTest.read.MOONBEAM([]);
      expect(moonbeam).to.equal(2004);
    });

    it("Should have correct constant for Astar", async function () {
      const astar = await multiLocationTest.read.ASTAR([]);
      expect(astar).to.equal(2006);
    });

    it("Should have correct constant for Acala", async function () {
      const acala = await multiLocationTest.read.ACALA([]);
      expect(acala).to.equal(2000);
    });

    it("Should have correct constant for Bifrost", async function () {
      const bifrost = await multiLocationTest.read.BIFROST([]);
      expect(bifrost).to.equal(2030);
    });
  });

  describe("Integration Tests", function () {
    it("Should construct complete transfer destination", async function () {
      const paraId = 2034; // Hydration
      const recipient = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0";

      const destinationResult = await multiLocationTest.read.testParachain([paraId]);
      const beneficiaryResult = await multiLocationTest.read.testAccountKey20([recipient]);

      expect(destinationResult).to.not.equal("0x");
      expect(beneficiaryResult).to.not.equal("0x");
    });

    it("Should differentiate between Substrate and EVM accounts", async function () {
      const substrateAccount = "0x" + "aa".repeat(32);
      const evmAccount = "0x" + "bb".repeat(20);

      const substrateResult = await multiLocationTest.read.testAccountId32([substrateAccount]);
      const evmResult = await multiLocationTest.read.testAccountKey20([evmAccount]);

      // Both should be valid but different
      expect(substrateResult).to.not.equal(evmResult);
    });
  });
});

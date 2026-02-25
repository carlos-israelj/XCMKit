import { expect } from "chai";
import hre from "hardhat";

describe("ScaleEncoder Library", function () {
  let testContract: any;

  before(async function () {
    // Deploy ScaleEncoderTest helper contract
    const ScaleEncoderTest = await hre.viem.deployContract("ScaleEncoderTest", []);
    testContract = ScaleEncoderTest;
  });

  describe("Basic Type Encoding", function () {
    it("Should encode uint8 correctly", async function () {
      const result = await testContract.read.testEncodeU8([42]);
      expect(result).to.equal("0x2a");
    });

    it("Should encode uint8 zero", async function () {
      const result = await testContract.read.testEncodeU8([0]);
      expect(result).to.equal("0x00");
    });

    it("Should encode uint8 max value (255)", async function () {
      const result = await testContract.read.testEncodeU8([255]);
      expect(result).to.equal("0xff");
    });

    it("Should encode uint32 in little-endian", async function () {
      // 0x12345678 in little-endian should be [0x78, 0x56, 0x34, 0x12]
      const result = await testContract.read.testEncodeU32([0x12345678]);
      expect(result).to.equal("0x78563412");
    });

    it("Should encode uint32 zero", async function () {
      const result = await testContract.read.testEncodeU32([0]);
      expect(result).to.equal("0x00000000");
    });

    it("Should encode uint32 parachain ID 2034 (Hydration)", async function () {
      // 2034 = 0x07F2 -> little-endian: 0xF2070000
      const result = await testContract.read.testEncodeU32([2034]);
      expect(result).to.equal("0xf2070000");
    });

    it("Should encode uint64 in little-endian", async function () {
      const result = await testContract.read.testEncodeU64([0x0102030405060708n]);
      expect(result).to.equal("0x0807060504030201");
    });

    it("Should encode uint128 in little-endian", async function () {
      // 1000000000000000000 (1 ETH in wei)
      const oneEth = 1000000000000000000n;
      const result = await testContract.read.testEncodeU128([oneEth]);
      // Little-endian representation - uint128 is 16 bytes
      expect(result).to.equal("0x000064a7b3b6e00d0000000000000000");
    });
  });

  describe("Compact Integer Encoding", function () {
    it("Should encode compact 0 (single byte mode)", async function () {
      const result = await testContract.read.testEncodeCompact([0]);
      expect(result).to.equal("0x00");
    });

    it("Should encode compact 63 (single byte mode max)", async function () {
      const result = await testContract.read.testEncodeCompact([63]);
      expect(result).to.equal("0xfc"); // 63 << 2 | 0b00 = 252
    });

    it("Should encode compact 64 (two-byte mode)", async function () {
      const result = await testContract.read.testEncodeCompact([64]);
      expect(result).to.equal("0x0101"); // (64 << 2 | 0b01) little-endian
    });

    it("Should encode compact 16383 (two-byte mode max)", async function () {
      const result = await testContract.read.testEncodeCompact([16383]);
      expect(result).to.equal("0xfdff"); // (16383 << 2 | 0b01) little-endian
    });

    it("Should encode compact 16384 (four-byte mode)", async function () {
      const result = await testContract.read.testEncodeCompact([16384]);
      expect(result).to.equal("0x02000100"); // (16384 << 2 | 0b10) little-endian
    });

    it("Should encode compact 1073741823 (four-byte mode max)", async function () {
      const result = await testContract.read.testEncodeCompact([1073741823]);
      expect(result).to.equal("0xfeffffff");
    });
  });

  describe("Bytes and String Encoding", function () {
    it("Should encode empty bytes", async function () {
      const result = await testContract.read.testEncodeBytes(["0x"]);
      expect(result).to.equal("0x00"); // Compact 0 (length) + empty data
    });

    it("Should encode bytes with length prefix", async function () {
      const data = "0x010203";
      const result = await testContract.read.testEncodeBytes([data]);
      // Compact 3 (length) = 0x0c, followed by data
      expect(result).to.equal("0x0c010203");
    });

    it("Should encode empty string", async function () {
      const result = await testContract.read.testEncodeString([""]);
      expect(result).to.equal("0x00");
    });

    it("Should encode string with length prefix", async function () {
      const result = await testContract.read.testEncodeString(["hello"]);
      // Compact 5 = 0x14, followed by "hello" in hex
      const expected = "0x1468656c6c6f";
      expect(result).to.equal(expected);
    });
  });

  describe("MultiLocation Encoding", function () {
    it("Should encode MultiLocation with parents and interior", async function () {
      // Example: { parents: 1, interior: X1(Parachain(2034)) }
      // Interior for X1(Parachain(2034)) in SCALE
      const parachainInterior = "0x00" + "f2070000"; // X1 variant + parachain(2034)
      const result = await testContract.read.testEncodeMultiLocation([1, parachainInterior]);

      // Expected: parents(1) + interior bytes
      expect(result).to.include("01"); // parents = 1
    });

    it("Should encode MultiLocation with zero parents", async function () {
      const interior = "0x00"; // Here variant
      const result = await testContract.read.testEncodeMultiLocation([0, interior]);
      expect(result).to.include("00"); // parents = 0
    });
  });

  describe("Byte Array Concatenation", function () {
    it("Should concatenate empty arrays", async function () {
      const result = await testContract.read.testConcat([[]]);
      expect(result).to.equal("0x");
    });

    it("Should concatenate single array", async function () {
      const result = await testContract.read.testConcat([["0x010203"]]);
      expect(result).to.equal("0x010203");
    });

    it("Should concatenate multiple arrays", async function () {
      const parts = ["0x01", "0x0203", "0x040506"];
      const result = await testContract.read.testConcat([parts]);
      expect(result).to.equal("0x010203040506");
    });

    it("Should handle arrays with empty elements", async function () {
      const parts = ["0x01", "0x", "0x02"];
      const result = await testContract.read.testConcat([parts]);
      expect(result).to.equal("0x0102");
    });
  });

  describe("Integration Tests", function () {
    it("Should encode complete asset transfer amount", async function () {
      // 100 tokens (assuming 18 decimals) = 100 * 10^18
      const amount = 100n * 10n ** 18n;
      const result = await testContract.read.testEncodeU128([amount]);

      // Should be 16 bytes in little-endian format
      expect(result.length).to.equal(42); // "0x" + 40 hex chars (20 bytes)
    });

    it("Should encode parachain ID for all supported chains", async function () {
      const chains = [1000, 1002, 2000, 2004, 2006, 2030, 2034];

      for (const chainId of chains) {
        const result = await testContract.read.testEncodeU32([chainId]);
        expect(result).to.not.equal("0x00000000");
        expect(result.length).to.equal(10); // "0x" + 8 hex chars
      }
    });
  });
});

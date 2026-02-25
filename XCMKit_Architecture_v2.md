# XCMKit — Architecture & Project Document v2

> **Polkadot Solidity Hackathon 2026 | Track 2: PVM Smart Contracts — Accessing Polkadot native functionality via precompiles**

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Strategy: Camino A](#strategy-camino-a)
3. [Problem Statement](#problem-statement)
4. [Solution](#solution)
5. [What XCMKit Is Not](#what-xcmkit-is-not)
6. [Architecture](#architecture)
7. [API Design](#api-design)
8. [Tech Stack](#tech-stack)
9. [Critical Constraints](#critical-constraints)
10. [Development Roadmap](#development-roadmap)
11. [Ecosystem Fit & Competitive Analysis](#ecosystem-fit--competitive-analysis)
12. [Grant Alignment](#grant-alignment)
13. [Future Plans](#future-plans)
14. [References](#references)
15. [Implementation Guide](#implementation-guide)

---

## 🌟 Project Overview

**Project name:** XCMKit  
**Tagline:** The first Solidity library for on-chain XCM execution on Polkadot Hub.  
**Track:** Track 2 — PVM Smart Contracts / Accessing Polkadot native functionality via precompiles  
**License:** MIT  

XCMKit is an open-source Solidity library that abstracts the raw XCM precompile on Polkadot Hub into a developer-friendly API. Any smart contract can import XCMKit and execute cross-chain transfers, send XCM messages, and compose XCM programs — with no external dependencies, no off-chain infrastructure, and no user interaction required.

The primary deliverable is the **library itself**. A lightweight interactive playground demonstrates all library functions running live on Passet Hub testnet.

---

## 🎯 Strategy: Camino A

### Why a library, not an app

The hackathon FAQ specifies that Track 2 (PVM Smart Contracts) is for projects that use *"Polkadot native functionality via precompiles"*. The three categories in this track are:

- PVM-experiments — call Rust/C++ from Solidity
- Applications using Polkadot native assets
- **Accessing Polkadot native functionality — build with precompiles** ← XCMKit

The judging criteria weights five factors equally: technical implementation, use of Polkadot Hub features, innovation & impact, UX and adoption potential, team execution. A well-executed library scores at the top of the first three — the most differentiating criteria — and a playground covers UX sufficiently for Demo Day.

Submitting an app with social login and a full frontend stack (Camino B) would dilute the technical signal, add execution risk across 4 weeks, and compete against apps in Track 1 (EVM Smart Contracts) that are purpose-built for DeFi/AI consumer use cases.

### How this maps to judging criteria

| Judging Criterion | XCMKit response |
|---|---|
| **Technical implementation** | SCALE encoding in Solidity, MultiLocation construction, XCM program assembly, weight estimation via precompile |
| **Use of Polkadot Hub features** | Direct precompile calls at `0x00000000000000000000000000000000000a0000` — the deepest possible use of Hub-native functionality |
| **Innovation & impact** | First Solidity library for on-chain XCM — no existing alternative, fills a gap acknowledged in official Polkadot docs |
| **UX and adoption potential** | Interactive playground demonstrating all core functions live on Passet Hub — any developer can clone, deploy, and call `XCMKit.transfer()` in under 10 minutes |
| **Team execution** | Focused scope: Solidity library + tests + playground. No Web3Auth, no wagmi codegen, no social auth complexity |

### What the demo looks like on Demo Day

A browser-based playground connected to Passet Hub testnet. The presenter selects a destination parachain, enters an amount, clicks "Transfer" — and within seconds a cross-chain transfer appears on Blockscout and XCM Tracker. The entire demo runs in under 2 minutes. The code executing is `XCMKit.transfer()` — one line of Solidity.

---

## 🔴 Problem Statement

Polkadot Hub supports EVM-compatible smart contracts via `pallet-revive`. The XCM precompile is live at `0x00000000000000000000000000000000000a0000` and exposes three low-level functions: `execute`, `send`, and `weighMessage`.

The official Polkadot documentation states explicitly:

> *"The XCM precompile provides the barebones XCM functionality. While it provides a lot of flexibility, **it doesn't provide abstractions to hide away XCM details. These have to be built on top.**"*

Any Solidity developer wanting cross-chain functionality today must:

- Manually encode XCM messages using SCALE codec — a Substrate-native binary format with no Solidity tooling
- Construct MultiLocation structs — a hierarchical addressing system with no EVM equivalent
- Estimate computational weights by calling `weighMessage` and parsing the result
- Assemble instruction sequences (WithdrawAsset, BuyExecution, DepositAsset) in the correct order and format

This is a significant barrier. There is no published Solidity SDK for the XCM precompile. Parity's own internal library (XTransfers) has been in development since September 2025 with no public release as of March 2026.

---

## ✅ Solution

XCMKit wraps the raw precompile with purpose-built Solidity libraries that expose human-readable functions:

```solidity
// Without XCMKit — developer must build this manually:
bytes memory message = hex"050c000401000003008c86471301000003008c8647...";
IXcm.Weight memory weight = xcm.weighMessage(message);
xcm.execute(message, weight);

// With XCMKit — one line:
XCMKit.transfer(Destination.HYDRATION, recipient, token, amount);
```

The library handles SCALE encoding, weight estimation, MultiLocation construction, and XCM instruction sequencing internally. The developer only provides the parameters that matter: where, who, what, how much.

---

## 🚫 What XCMKit Is Not

**XCMKit is not an off-chain SDK.**  
[ParaSpell](https://paraspell.github.io/docs/) is the dominant XCM toolset for TypeScript/Substrate developers — SDK, REST API, Router, 68+ chains, funded through July 2026. All of it runs off-chain: builds unsigned transactions, requires user signatures, needs WebSocket connections and npm packages. XCMKit runs on-chain in Solidity with zero external dependencies. A contract can call `XCMKit.transfer()` autonomously — no human present, no backend running, no signature required.

**XCMKit is not a bridge.**  
It works within the Polkadot ecosystem via HRMP channels between Polkadot Hub and connected parachains. Snowbridge and Hyperbridge handle Ethereum connectivity.

**XCMKit is not a replacement for XTransfers.**  
Parity's XTransfers library is internal, undocumented, and unreleased. XCMKit is community-built, MIT-licensed, available now, and focused specifically on Solidity/EVM developer experience.

**XCMKit does not cover all XCM use cases.**  
Milestone 1 scope: reserve transfers, teleports, and Snowbridge bridge transfers via high-level functions (`transfer`, `transferWithFee`, `teleport`, `transferToEvm`). Arbitrary XCM program composition (`buildProgram`, `execute`) is Milestone 2. Advanced patterns (remote execution, QueryResponse, version negotiation) are explicitly out of scope for v1.

---

## 🏗️ Architecture

### System overview

```
┌─────────────────────────────────────────────────────────────┐
│                    XCMKit Project                           │
│                   (MIT license)                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              XCMKit Playground (demo)               │   │
│   │   React + Vite + ethers.js                          │   │
│   │                                                     │   │
│   │   - Destination selector (parachain presets)        │   │
│   │   - Token + amount + recipient input                │   │
│   │   - Fee estimation preview                          │   │
│   │   - One-click transfer execution                    │   │
│   │   - XCM message tracker (Ocelloids)                 │   │
│   │   - Link to Blockscout tx                           │   │
│   └─────────────────────┬───────────────────────────────┘   │
│                         │ ethers.js contract calls          │
│   ┌─────────────────────▼───────────────────────────────┐   │
│   │              XCMBridge.sol (demo contract)           │   │
│   │         deployed on Passet Hub testnet               │   │
│   │                                                      │   │
│   │  function transfer(destination, recipient,           │   │
│   │                    token, amount) external           │   │
│   │  function estimateFee(destination, token,            │   │
│   │                       amount) external view          │   │
│   │                                                      │   │
│   │  uses → XCMKit library functions                     │   │
│   └─────────────────────┬───────────────────────────────┘   │
│                         │ library calls (linked at compile)  │
│   ┌─────────────────────▼───────────────────────────────┐   │
│   │          XCMKit Solidity Libraries                   │   │
│   │        (the actual deliverable)                      │   │
│   │                                                      │   │
│   │  library XCMKit        — public entry point          │   │
│   │  library ScaleEncoder  — SCALE byte encoding         │   │
│   │  library MultiLocation — destination builder         │   │
│   │  library XCMProgram    — instruction assembler       │   │
│   │  library WeightHelper  — weight estimation           │   │
│   └─────────────────────┬───────────────────────────────┘   │
│                         │ low-level precompile calls         │
│   ┌─────────────────────▼───────────────────────────────┐   │
│   │       IXcm Precompile (Polkadot Hub native)          │   │
│   │  Address: 0x00000000000000000000000000000a0000       │   │
│   │  Functions: execute | send | weighMessage            │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Project structure

```
xcmkit/
├── contracts/                        ← XCMKit library + demo contract
│   ├── contracts/
│   │   ├── XCMBridge.sol             ← Demo coordinator contract
│   │   ├── libs/
│   │   │   ├── XCMKit.sol            ← Main library (public entry point)
│   │   │   ├── ScaleEncoder.sol      ← SCALE encoding library
│   │   │   ├── MultiLocation.sol     ← Destination builder library
│   │   │   ├── XCMProgram.sol        ← Instruction assembler library
│   │   │   └── WeightHelper.sol      ← Weight estimation library
│   │   └── interfaces/
│   │       └── IXcm.sol              ← Precompile interface (from Parity SDK)
│   ├── test/                         ← Hardhat unit + integration tests
│   ├── ignition/                     ← Deployment modules
│   └── hardhat.config.ts             ← @parity/hardhat-polkadot config
├── playground/                       ← Demo frontend (minimal React app)
│   ├── src/
│   │   ├── components/
│   │   └── lib/
│   ├── package.json
│   └── vite.config.ts
├── AGENTS.md                         ← LLM context file (Claude Code, Cursor)
├── README.md
└── package.json                      ← Monorepo root
```

### Core contracts

| Contract/Library | Type | Responsibility |
|---|---|---|
| `XCMBridge.sol` | Contract (deployed) | Demo coordinator — public functions called by playground |
| `XCMKit.sol` | Library | Main entry point — routes calls to internal libs |
| `ScaleEncoder.sol` | Library | Encodes Solidity types into SCALE byte format |
| `MultiLocation.sol` | Library | Constructs XCM destination structs |
| `XCMProgram.sol` | Library | Assembles XCM instruction sequences |
| `WeightHelper.sol` | Library | Calls `weighMessage` and returns computed Weight |

### Core design principles

- **Library pattern, not framework** — import, don't inherit. `using XCMKit for *` or direct `XCMKit.transfer(...)` calls.
- **Zero external dependencies** — pure Solidity. Compiles into the consuming contract, no separate deployment.
- **Bytecode-aware** — stateless (no mappings, no arrays, no persistent state). Precompile delegation keeps bytecode minimal.
- **Composable** — functions work standalone or chained. `buildProgram` + `execute` enable arbitrary XCM instruction sequences.
- **Auditable** — pure functions with deterministic outputs. Same inputs always produce the same SCALE bytes.

### Destination presets (v1)

```solidity
library Destination {
    uint32 constant ASSET_HUB   = 1000;
    uint32 constant BRIDGE_HUB  = 1002;
    uint32 constant HYDRATION   = 2034;
    uint32 constant MOONBEAM    = 2004;
    uint32 constant ASTAR       = 2006;
    uint32 constant ACALA       = 2000;
    uint32 constant BIFROST     = 2030;
}
```

### XCM instruction flow — reserve transfer

A standard reserve transfer to Hydration compiles to the following XCM instruction sequence:

```
WithdrawAsset      ← remove tokens from sender on Hub
ClearOrigin        ← drop origin context (trustless)
BuyExecution       ← pay XCM execution fees on destination
DepositAsset       ← credit recipient on Hydration
```

`XCMProgram.sol` assembles this sequence. `ScaleEncoder.sol` encodes each instruction into SCALE bytes. `WeightHelper.sol` calls `weighMessage` on the precompile to get the Weight struct before calling `execute`.

---

## 📐 API Design

### XCMKit public API

```solidity
library XCMKit {
    /**
     * @notice Transfer tokens to a destination parachain via reserve transfer
     * @param destinationParaId  Parachain ID (use Destination.HYDRATION etc.)
     * @param recipient          Recipient address on the destination chain
     * @param token              Token address on Polkadot Hub
     * @param amount             Amount in token decimals
     */
    function transfer(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) internal { ... }

    /**
     * @notice Transfer with explicit fee cap — protects against fee slippage
     */
    function transferWithFee(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount,
        uint256 maxFee
    ) internal { ... }

    /**
     * @notice Teleport for trusted system chains (AssetHub, BridgeHub)
     */
    function teleport(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) internal { ... }

    /**
     * @notice Bridge to Ethereum via Snowbridge
     */
    function transferToEvm(
        address evmRecipient,
        address token,
        uint256 amount
    ) internal { ... }

    /**
     * @notice Estimate fee before executing transfer
     * @return weight   Computed Weight struct (refTime, proofSize)
     * @return feePas   Estimated fee in PAS
     */
    function estimateFee(
        uint32 destinationParaId,
        address token,
        uint256 amount
    ) internal view returns (IXcm.Weight memory weight, uint256 feePas) { ... }

    /**
     * @notice Build and execute arbitrary XCM programs — Milestone 2
     * @dev Takes an array of XCMInstruction structs, SCALE-encodes them,
     *      and returns the full XCM message ready for execute()
     */
    function buildProgram(
        XCMInstruction[] memory instructions
    ) internal returns (bytes memory encodedProgram) { ... }

    /// @notice Execute a pre-built XCM program — Milestone 2
    function execute(bytes memory xcmProgram) internal returns (bool) { ... }

    /**
     * @notice Send a raw XCM message to a destination parachain — Milestone 2
     * @dev Lower-level than transfer(); caller is responsible for message encoding
     */
    function send(
        uint32 destinationParaId,
        bytes memory message
    ) internal { ... }

    /**
     * @notice Query foreign asset balance for an account on a destination chain — Milestone 2
     * @param location  XCM MultiLocation of the asset to query
     * @return balance  Asset balance at the queried location
     */
    function queryAssets(
        bytes memory location
    ) internal view returns (uint256 balance) { ... }
}
```

### ScaleEncoder internal API

```solidity
library ScaleEncoder {
    function encodeU8(uint8 value) internal pure returns (bytes memory)
    function encodeU32(uint32 value) internal pure returns (bytes memory)
    function encodeU64(uint64 value) internal pure returns (bytes memory)
    function encodeU128(uint128 value) internal pure returns (bytes memory)
    function encodeCompact(uint256 value) internal pure returns (bytes memory)
    function encodeBytes(bytes memory data) internal pure returns (bytes memory)
    function encodeMultiLocation(uint8 parents, bytes memory interior)
        internal pure returns (bytes memory)
}
```

### MultiLocation internal API

```solidity
library MultiLocation {
    // { parents: 1, interior: X1(Parachain(id)) }
    function parachain(uint32 paraId)
        internal pure returns (bytes memory)

    // { parents: 0, interior: X1(AccountId32(addr)) }
    function accountId32(bytes32 accountId)
        internal pure returns (bytes memory)

    // Concrete asset location for a token on Hub
    function assetLocation(address token)
        internal pure returns (bytes memory)
}
```

### XCMProgram types (Milestone 2)

```solidity
// Supported XCM opcodes for buildProgram()
enum XCMOpcode {
    WithdrawAsset,
    ClearOrigin,
    BuyExecution,
    DepositAsset,
    ExchangeAsset,
    InitiateReserveWithdraw,
    ReceiveTeleportedAsset,
    ReserveAssetDeposited
}

// Instruction unit passed to buildProgram()
struct XCMInstruction {
    XCMOpcode opcode;
    bytes     payload;   // SCALE-encoded instruction data
}
```

`buildProgram` takes an array of `XCMInstruction` structs, encodes them into a valid SCALE-encoded XCM message, and returns the bytes ready to pass to `execute`. This is the low-level escape hatch for use cases beyond the high-level `transfer()` API.

---

## 💡 Use Cases XCMKit Enables

These use cases are architecturally impossible with any off-chain tool including ParaSpell — they require on-chain conditions to trigger cross-chain execution without user presence.

### DeFi Auto-Routing

```solidity
contract LiquidityRouter {
    IOracle public oracle;
    uint256 public rebalanceThreshold = 200; // 2% APY difference

    function rebalance() external {
        uint256 hydrationAPY = oracle.getAPY('Hydration');
        uint256 localAPY    = oracle.getAPY('PolkadotHub');

        if (hydrationAPY > localAPY + rebalanceThreshold) {
            XCMKit.transfer(Destination.HYDRATION, pool, DOT, liquidity);
        }
    }
}
```

### Cross-Chain Vesting

```solidity
contract VestingSchedule {
    address public beneficiary;
    uint256 public vestingEnd;

    function release() external {
        require(block.timestamp >= vestingEnd, 'Not yet');
        uint256 amount = IERC20(dotToken).balanceOf(address(this));
        XCMKit.transfer(Destination.ASTAR, beneficiary, dotToken, amount);
    }
}
```

### Multisig Cross-Chain Execution

```solidity
contract MultiSigXCM {
    mapping(address => bool) public signers;
    uint256 public threshold;
    uint256 public approvals;

    function approve() external onlySigner {
        approvals++;
        if (approvals >= threshold) {
            XCMKit.transfer(Destination.MOONBEAM, destination, GLMR, amount);
            approvals = 0;
        }
    }
}
```

### On-Chain Swap via ExchangeAsset (Milestone 2)

```solidity
contract OnChainSwap {
    function swapDOTtoUSDC(uint256 amount, uint256 minOut) external {
        XCMInstruction[] memory program = new XCMInstruction[](3);
        program[0] = XCMInstruction(XCMOpcode.WithdrawAsset, encodeDOT(amount));
        program[1] = XCMInstruction(XCMOpcode.ExchangeAsset,
            encodeSwap(DOT_LOCATION, USDC_LOCATION, minOut));
        program[2] = XCMInstruction(XCMOpcode.DepositAsset, encodeRecipient());
        XCMKit.execute(XCMKit.buildProgram(program));
    }
}
```

---

## 🛠️ Tech Stack

### Contracts

| Tool | Version | Purpose |
|---|---|---|
| Solidity | `^0.8.28` | Contract language (required for PolkaVM) |
| `@parity/hardhat-polkadot` | `^0.1.7` | Hardhat plugin for PolkaVM deployment |
| `resolc` | `0.3.0` | PolkaVM-compatible compiler (required) |
| `solc` | `0.8.28` | Base Solidity compiler |
| `@nomicfoundation/hardhat-toolbox` | `^5.0.0` | Testing, coverage, typechain |
| OpenZeppelin | N/A | **No usar OZ estándar** — causa `initcode is too big`. XCMBridge.sol usa `onlyOwner` y `nonReentrant` inline (ver Implementation Guide). Para proyectos más grandes evaluar `papermoonio/openzeppelin-contracts-polkadot`. |
| Chopsticks | latest | Local fork of Passet Hub for integration tests |

### Hardhat configuration

```typescript
// hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@parity/hardhat-polkadot";
import { vars } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: "0.8.28",           // MUST be string format
  resolc: {
    version: "0.3.0",
    compilerSource: "npm",
  },
  networks: {
    hardhat: {
      polkavm: true,
    },
    localNode: {
      polkavm: true,
      url: "http://127.0.0.1:8545",
    },
    passetHub: {
      polkavm: true,
      url: "https://testnet-passet-hub-eth-rpc.polkadot.io",
      accounts: [vars.get("PRIVATE_KEY")],
    },
  },
};

export default config;
```

### Playground (demo frontend)

| Tool | Purpose |
|---|---|
| React + Vite | Minimal frontend — no framework overhead |
| ethers.js v6 | Contract interaction |
| MetaMask / Talisman | Wallet connection — no social login needed |
| Ocelloids XCM Tracker | Live XCM message status |

The playground is intentionally minimal. Its purpose is to demonstrate the library in action for Demo Day, not to be a production app.

### Network configuration

```typescript
export const PASSET_HUB = {
  chainId: 420420422,
  chainIdHex: '0x1911f0a6',
  name: 'Passet Hub',
  rpcUrl: 'https://testnet-passet-hub-eth-rpc.polkadot.io',
  blockExplorer: 'https://blockscout-passet-hub.parity-testnet.parity.io',
  currency: 'PAS',
  faucet: 'https://faucet.polkadot.io/?parachain=1111',
};
```

### Infrastructure

| Service | Purpose |
|---|---|
| Vercel | Playground hosting |
| OnFinality | RPC endpoints (free tier for builders) |
| Blockscout (Passet Hub) | Transaction verification in demo |
| Ocelloids XCM Tracker | Live XCM message tracking in demo |

---

## ⚠️ Critical Constraints

### Bytecode limit: 100KB (validated — not a blocker)

PolkaVM enforces a ~100KB bytecode limit per deployed contract. **This is not a concern for XCMKit** because the library uses Solidity `internal` functions — they link into the consuming contract at compile time and never exist as a standalone deployed contract. The Kitdot full-stack template ships with OpenZeppelin by default, confirming standard OZ patterns work within the limit.

Use OZ estándar: **no**. Usar patterns inline (`onlyOwner`, `nonReentrant`) documentados en Implementation Guide. Run `npx hardhat size-contracts` on `XCMBridge.sol` como check de rutina. XCMKit's design keeps that number low by default:
- Stateless — no mappings, no arrays, no persistent state
- Precompile delegation — heavy encoding work handled by the precompile at call time

### XCM V4/V5 compatibility

Polkadot Hub runs XCM V5. Destination chains range from V3 to V5. XCMKit normalizes to the highest mutually supported version per destination. `XCMProgram.sol` handles version wrapping internally — consumers never deal with version bytes.

### PolkaVM opcode differences

Some EVM opcodes behave differently in PolkaVM. XCMKit stays within the well-supported subset. Key reference: [PolkaVM: Missing Opcodes and Workarounds](https://polkadotsolidity.com/blog/polkavm-missing-opcodes-and-workarounds) (January 2026 hackathon resource).

### Precompile address stability

The XCM precompile address is implementation-defined and could change with a runtime upgrade. XCMKit exposes it as a named constant:

```solidity
address constant XCM_PRECOMPILE = 0x00000000000000000000000000000000000a0000;
```

Single-line change to update across the entire library.

### Required setup

```bash
# Installation
npm install --save-dev @parity/hardhat-polkadot solc@0.8.28
npm install --force @nomicfoundation/hardhat-toolbox

# Private key — never commit
npx hardhat vars set PRIVATE_KEY
```

### Common errors

| Error | Cause | Fix |
|---|---|---|
| `CodeRejected` | Missing `polkavm: true` or `resolc` | Add both to `hardhat.config.ts` |
| `initcode is too big` | Contract > 100KB | Use library pattern, check `size-contracts` |
| `Cannot read properties of undefined` | Solidity version not string | Use `solidity: "0.8.28"` not `{version: ...}` |
| `No signers found` | Missing private key | `npx hardhat vars set PRIVATE_KEY` |

---

## 📅 Development Roadmap

### Hackathon timeline

| Date | Event |
|---|---|
| Feb 16, 2026 | Registration opens |
| Mar 1, 2026 | Hacking period begins |
| Mar 20, 2026 | Project submission deadline |
| Mar 24-25, 2026 | Demo Day (camera on, 1-3 min demo required) |

---

### Milestone 1 — XCMKit Core Library (Hackathon, Mar 1–20)

**Goal:** Working, tested Solidity library for reserve transfers, teleports, and Snowbridge bridge transfers. Deployed on Passet Hub testnet with a live playground demo.

| # | Deliverable | Spec |
|---|---|---|
| 0a | License | MIT in repo root |
| 0b | NatSpec docs | All public functions documented with NatSpec |
| 0c | Unit tests | `npx hardhat test` — ScaleEncoder, MultiLocation, XCMProgram, WeightHelper, XCMKit |
| 1 | `IXcm.sol` | Precompile interface — verbatim from Parity SDK |
| 2 | `ScaleEncoder.sol` | SCALE encoding: u8, u32, u64, u128, compact, bytes, MultiLocation |
| 3 | `MultiLocation.sol` | Builders: `parachain()`, `accountId32()`, `assetLocation()` |
| 4 | `XCMProgram.sol` | Instruction assembly: WithdrawAsset + ClearOrigin + BuyExecution + DepositAsset |
| 5 | `WeightHelper.sol` | `weighMessage` precompile call → `IXcm.Weight` |
| 6 | `XCMKit.sol` | Public API: `transfer()`, `transferWithFee()`, `teleport()`, `transferToEvm()`, `estimateFee()` |
| 7 | `XCMBridge.sol` | Demo coordinator contract — wraps XCMKit for frontend calls |
| 8 | Playground | Minimal React + Vite app: destination selector, amount input, fee preview, transfer execution, Blockscout + XCM Tracker links |
| 9 | README | Setup guide, API reference, usage examples |

**Chain support:**

| Chain | Parachain ID | Reason |
|---|---|---|
| Hydration | 2034 | Largest DEX, 210 pools, ExchangeAsset supported |
| Moonbeam | 2004 | Largest EVM parachain, Solidity developer overlap |
| Astar | 2006 | Major EVM + Substrate hybrid |
| AssetHub Polkadot | 1000 | System chain, teleport supported |
| BridgeHub Polkadot | 1002 | Snowbridge Ethereum bridge |

**Verification:** All unit tests pass. Live transfer Passet Hub → Hydration visible in Blockscout and XCM Tracker. Playground runs on Vercel.

**Budget:** Hackathon submission (prize target: $3,000)

---

### Milestone 2 — XCM Program Composer + Developer Tooling (Post-hackathon, W3F Grant)

**Goal:** Extend XCMKit with arbitrary XCM program composition, cross-chain asset queries, comprehensive documentation, and npm package publication.

| # | Deliverable | Spec |
|---|---|---|
| 0a | License | MIT |
| 0b | NatSpec docs | All Milestone 2 functions documented |
| 0c | Unit tests | `buildProgram`, `execute`, `queryAssets`, `estimateFee` v2 |
| 0d | Technical article | Published post: XCMKit internals, SCALE encoding approach, XCM instruction model, comparison vs raw precompile |
| 1 | `XCMProgram.sol` v2 | `buildProgram(XCMInstruction[])` + `execute(bytes)` — arbitrary XCM program composition |
| 2 | `XCMKit.sol` v2 | Adds `send()`, `buildProgram()`, `execute()`, `queryAssets()`, `estimateFee()` v2 |
| 3 | Integration tests | Chopsticks fork: end-to-end tests Passet Hub + Hydration + Moonbeam |
| 4 | Documentation | GitBook: API reference, step-by-step tutorial, raw precompile vs XCMKit comparison, known limitations |
| 5 | npm package | `@xcmkit/contracts` published on npm — `npm install @xcmkit/contracts` |
| 6 | `AGENTS.md` | LLM context file for Claude Code / Cursor: network config, deployment guide, common errors |

**Verification:** `npm install @xcmkit/contracts` works. Integration tests pass against Chopsticks fork. Technical article published. GitBook live.

**Budget:** $5,000 USD (~50 hours × $100/hr)

---

### Milestone 3 — Security Audit + Expanded Chain Support (Post-hackathon, W3F Grant)

**Goal:** Production-ready release with independent security audit, expanded parachain support, and token registry.

| # | Deliverable | Spec |
|---|---|---|
| 0a | License | MIT |
| 0b | NatSpec docs | Updated for all new functions |
| 0c | Unit + fuzz tests | Expanded test suite including fuzz testing for SCALE encoder edge cases |
| 1 | Security audit | Independent audit by W3F-approved auditor or Polkadot Assurance Legion subsidy |
| 2 | Audit fixes | All critical and high findings resolved, report published |
| 3 | Expanded chain support | `Destination` presets extended to top 10 parachains by TVL: adds Bifrost (2030), Interlay (2032), Manta (2104), Parallel (2012), Centrifuge (2031) |
| 4 | Token Registry | `TokenRegistry.sol` — on-chain mapping of foreign asset addresses by symbol: `TokenRegistry.address("DOT")`, `TokenRegistry.address("USDC")` |
| 5 | XCM version negotiation | Automatic downgrade to V3 for older destination chains |
| 6 | Reference implementations | Three production-ready example contracts: `CrossChainVesting.sol`, `AutoRebalancer.sol`, `MultiSigXCM.sol` |

**Verification:** Audit report published. All findings addressed. `@xcmkit/contracts` v1.0.0 tagged. Reference implementations deployed and verified on mainnet Polkadot Hub.

**Budget:** $5,000 USD (~50 hours × $100/hr)

---

### Milestone summary

| Milestone | Scope | Budget | Timeline |
|---|---|---|---|
| **1** | Core library + playground | Hackathon | Mar 1–20, 2026 |
| **2** | XCM composer + docs + npm | W3F Grant $5,000 | Apr–May 2026 |
| **3** | Audit + expanded chains + token registry | W3F Grant $5,000 | Jun–Jul 2026 |
| **Total post-hackathon** | | **$10,000** | |

### Testing strategy

- **Unit tests:** pure function tests for SCALE byte output, MultiLocation encoding, XCM program construction — no network required, run with `npx hardhat test`
- **Integration tests (M2):** Chopsticks fork of Passet Hub + Hydration + Moonbeam for end-to-end transfer tests against real chain state
- **Fuzz tests (M3):** property-based tests for `ScaleEncoder` edge cases — zero values, max uint128, malformed inputs
- **Testnet:** Passet Hub deployment verified on Blockscout and XCM Tracker after every deploy
- **Size checks:** `npx hardhat size-contracts` on `XCMBridge.sol` at every milestone

---

## 🧩 Ecosystem Fit & Competitive Analysis

### Where XCMKit fits

XCMKit is the **on-chain abstraction layer** for XCM on Polkadot Hub — the layer between the raw `pallet-xcm` precompile and application-layer contracts. This layer is currently empty.

### Target developers

- Solidity developers new to Polkadot who want cross-chain functionality without learning XCM internals
- Teams porting Ethereum DeFi protocols to Polkadot Hub
- Polkadot-native developers building autonomous cross-chain contracts

### Competitive landscape

| Project | Layer | Why it doesn't compete |
|---|---|---|
| **ParaSpell SDK/API/Router** | Off-chain (TypeScript) | Runs outside the chain. Requires user signatures, WebSocket connections, npm. Cannot be called from Solidity. |
| **XTransfers (Parity)** | On-chain (Solidity) | Internal, undocumented, unreleased as of Mar 2026. |
| **Moonbeam XCM Precompiles** | On-chain (Solidity) | Built for Moonbeam's runtime. Different precompile address and interface. |
| **asset-transfer-api** | Off-chain (TypeScript) | TypeScript library for frontend use. Not on-chain. |
| **pallet-contracts-xcm** | On-chain (ink!) | Rust/ink! contracts only. Different VM. |

### The ParaSpell distinction

```
ParaSpell (off-chain, pull model):
  User action → TypeScript SDK → unsigned tx → user signs → submits
  Authorization: always external

XCMKit (on-chain, push model):
  On-chain condition → XCMKit.transfer() → precompile → XCM sent
  Authorization: the contract itself
```

This enables use cases ParaSpell structurally cannot: autonomous DeFi rebalancing, time-locked vesting that releases cross-chain, multisig execution without a backend watcher.

### The XTransfers situation

Parity's September 2025 engineering update: *"continued work on the XTransfers library, making it simpler for contracts to move assets and messages across chains."*

5+ months later: no public repo, no documentation, no npm package. This validates both the problem difficulty and the market need. XCMKit fills the gap with a community-built, MIT-licensed, available-now alternative — with documentation and developer experience as first-class priorities that an internal Parity library may not prioritize.

---

## 💰 Grant Alignment

### Hackathon prizes (Track 2: PVM Smart Contracts)

| Place | Amount | Winners |
|---|---|---|
| 1st Prize | $3,000 | x2 |
| 2nd Prize | $2,000 | x2 |
| 3rd Prize | $1,000 | x2 |
| Honorable Mention | $500 | x6 |

Prize pool: $15,000 total across Track 2.

Additional: OpenGuild DeFi Builders Program referral, Polkadot Assurance Legion audit subsidy assessment, ecosystem marketing pipeline.

### Post-hackathon funding pathways

| Grant | Amount | Alignment |
|---|---|---|
| **W3F Grants** | Up to $100k | First Solidity XCM library, no W3F-funded competitor, open source |
| **Polkadot Open Source Grants** | Up to $30k | Library + npm package qualifies directly |

### Grant pipeline

```
Hackathon (Mar 2026)
  → Working v1 + demo video + open source repo
      → W3F Grant application with hackathon as proof of execution
          → Milestone 2: extended API + security audit
              → Treasury proposal: ecosystem-wide adoption
```

### Milestone structure alignment

The post-hackathon milestones are structured to match W3F Grant application format exactly — deliverable numbering (0a, 0b, 0c, 0d), verification criteria, cost breakdown. The hackathon submission doubles as the W3F grant application draft.

---

## 🔮 Future Plans

*Items below are beyond the 3-milestone roadmap — long-term ecosystem vision.*

**XCM Composer (v3.0)**  
Visual drag-and-drop XCM program builder that generates Solidity calldata — for developers and auditors who need to inspect or compose XCM logic without writing SCALE encoding by hand.

**Autonomous Strategy Templates**  
A curated library of production-ready DeFi patterns built on XCMKit: cross-chain yield optimizer, time-locked vesting with auto-release, DAO treasury rebalancer, keeper-triggered liquidity router. Each ships as a standalone contract that any team can fork and deploy.

**Polkadot Hub SDK (v4.0)**  
Expand beyond XCM to cover the full surface area of Polkadot Hub precompiles: staking, governance, identity, and asset management — all through the same developer-friendly Solidity API pattern established by XCMKit.

**Multi-VM support**  
Port XCMKit patterns to ink! (Rust) so the same abstractions are available to WASM contract developers on chains like Astar and Phala.

---

## 📎 References

**Official Polkadot documentation**
- [XCM Precompile Docs](https://docs.polkadot.com/develop/smart-contracts/precompiles/xcm-precompile/)
- [IXcm.sol source](https://github.com/paritytech/polkadot-sdk/blob/master/polkadot/xcm/pallet-xcm/src/precompiles/IXcm.sol)
- [Hardhat for Polkadot](https://docs.polkadot.com/develop/smart-contracts/dev-environments/hardhat/)
- [PolkaVM: Missing Opcodes and Workarounds](https://polkadotsolidity.com/blog/polkavm-missing-opcodes) — hackathon resource, Jan 2026
- [Polkadot Hackathon Survival Guide](https://github.com/polkadot-developers/hackathon-guide)

**Hackathon**
- [Polkadot Solidity Hackathon 2026](https://polkadotsolidity.com)
- [Track 2: PVM Smart Contracts](https://polkadotsolidity.com/#tracks)
- DoraHacks submission platform

**Scaffolding and tooling**
- [Kitdot](https://github.com/w3b3d3v/kitdot) — full-stack scaffolding reference
- [create-polkadot-dapp](https://github.com/paritytech/create-polkadot-dapp) — base template
- [hardhat-polkadot-example](https://github.com/UtkarshBhardwaj007/hardhat-polkadot-example) — reference config
- [LLMCONTRACTS.md](https://www.kusamahub.com/downloads/LLMCONTRACTS.md) — PolkaVM guide for AI agents

**Competitive landscape**
- [ParaSpell XCM SDK](https://paraspell.github.io/docs/)
- [Parity September 2025 Engineering Update (XTransfers)](https://www.parity.io/blog/build-on-polkadot-september-2025-product-engineering-update)
- [Moonbeam XCM Precompiles](https://docs.moonbeam.network/builders/interoperability/xcm/xcm-transactor/)

**XCM tracking**
- [Ocelloids XCM Tracker](https://xcm-tracker.ocelloids.net/)
- [Blockscout Passet Hub](https://blockscout-passet-hub.parity-testnet.parity.io/)

**Grants**
- [W3F Grants Program](https://grants.web3.foundation/docs/Process/how-to-apply)
- [Polkadot Open Source Grants](https://github.com/PolkadotOpenSourceGrants)
- [Polkadot Assurance Legion](https://polkadot-assurance-legion.github.io/)

---

*Document version: 2.0 — February 2026*  
*Track: Polkadot Solidity Hackathon 2026 — Track 2: PVM Smart Contracts / Precompiles*

**Changelog v2.0:**
- Strategy corregida a Camino A — librería + playground, sin app completa
- Hackathon info correcta: Track 2 PVM, $3k 1st prize, Demo Day obligatorio con cámara
- XCMBridge eliminado como app principal — pasa a ser demo contract
- Web3Auth / social login eliminado — playground usa MetaMask
- Timeline del hackathon documentado (Mar 1 → Mar 20 → Mar 24-25)
- Criterios de evaluación reales de los organizadores incluidos
- Premios adicionales documentados (OpenGuild DeFi Program, PAL audit subsidy)
- W3F grant milestones separados del hackathon
- Estructura de carpetas simplificada (`contracts/` + `playground/`)
- Competitive landscape actualizado con posicionamiento correcto

---

## 🔧 Implementation Guide

> Esta sección contiene todo lo que Claude Code necesita para implementar XCMKit sin preguntas. Lee esto antes de escribir cualquier contrato.

---

### IXcm.sol — Interface oficial verbatim

Este es el contrato exacto que debes copiar en `contracts/interfaces/IXcm.sol`. No modificar.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev The on-chain address of the XCM (Cross-Consensus Messaging) precompile.
address constant XCM_PRECOMPILE_ADDRESS = address(0xA0000);

/// @title XCM Precompile Interface
/// @notice A low-level interface for interacting with pallet_xcm.
/// @dev Documentation:
/// @dev - XCM: https://docs.polkadot.com/develop/interoperability
/// @dev - SCALE codec: https://docs.polkadot.com/polkadot-protocol/parachain-basics/data-encoding
/// @dev - Weights: https://docs.polkadot.com/polkadot-protocol/parachain-basics/blocks-transactions-fees/fees/
interface IXcm {
    /// @notice Weight v2 used for measurement for an XCM execution
    struct Weight {
        /// @custom:property The computational time used to execute some logic based on reference hardware.
        uint64 refTime;
        /// @custom:property The size of the proof needed to execute some logic.
        uint64 proofSize;
    }

    /// @notice Executes an XCM message locally on the current chain with the caller's origin.
    /// @dev Internally calls pallet_xcm::execute.
    /// @param message A SCALE-encoded Versioned XCM message.
    /// @param weight The maximum allowed Weight for execution.
    function execute(bytes calldata message, Weight calldata weight) external;

    /// @notice Sends an XCM message to another parachain or consensus system.
    /// @dev Internally calls pallet_xcm::send.
    /// @param destination SCALE-encoded destination MultiLocation.
    /// @param message SCALE-encoded Versioned XCM message.
    function send(bytes calldata destination, bytes calldata message) external;

    /// @notice Estimates the Weight required to execute a given XCM message.
    /// @param message SCALE-encoded Versioned XCM message to analyze.
    /// @return weight Struct containing estimated refTime and proofSize.
    function weighMessage(bytes calldata message) external view returns (Weight memory weight);
}
```

**Nota crítica:** La dirección corta `address(0xA0000)` y la larga `0x00000000000000000000000000000000000a0000` son equivalentes en Solidity. Usar la corta en el código.

---

### SCALE Encoding — Reglas de implementación

ScaleEncoder.sol debe implementar estas reglas exactas. Cada función produce bytes que el precompile consume directamente.

#### Integers de ancho fijo — little-endian

```
u8  (1 byte):  valor directo
u16 (2 bytes): little-endian
u32 (4 bytes): little-endian
u64 (8 bytes): little-endian
u128(16 bytes): little-endian

Ejemplo u32(420420422):
  420420422 = 0x190FA406
  little-endian → bytes: 06 A4 0F 19
```

En Solidity:
```solidity
function encodeU32(uint32 value) internal pure returns (bytes memory) {
    bytes memory result = new bytes(4);
    result[0] = bytes1(uint8(value));
    result[1] = bytes1(uint8(value >> 8));
    result[2] = bytes1(uint8(value >> 16));
    result[3] = bytes1(uint8(value >> 24));
    return result;
}
```

#### Compact encoding — enteros de longitud variable

SCALE compact es la codificación más usada en XCM para cantidades de tokens y lengths.

| Rango | Modo | Bytes | Fórmula |
|---|---|---|---|
| 0–63 | Single | 1 | `value << 2` |
| 64–16,383 | Two-byte | 2 | `(value << 2) \| 0x01`, little-endian |
| 16,384–1,073,741,823 | Four-byte | 4 | `(value << 2) \| 0x02`, little-endian |
| ≥1,073,741,824 | Big-integer | variable | `((byteLen-4) << 2) \| 0x03` + bytes |

```solidity
function encodeCompact(uint256 value) internal pure returns (bytes memory) {
    if (value <= 63) {
        return abi.encodePacked(uint8(value << 2));
    } else if (value <= 16_383) {
        uint16 v = uint16((value << 2) | 0x01);
        return abi.encodePacked(uint8(v), uint8(v >> 8));
    } else if (value <= 1_073_741_823) {
        uint32 v = uint32((value << 2) | 0x02);
        return abi.encodePacked(uint8(v), uint8(v>>8), uint8(v>>16), uint8(v>>24));
    } else {
        // Big-integer mode — for token amounts > 1B
        // Count bytes needed for value
        uint256 tmp = value;
        uint8 byteLen = 0;
        while (tmp > 0) { tmp >>= 8; byteLen++; }
        bytes memory result = new bytes(1 + byteLen);
        result[0] = bytes1(uint8(((byteLen - 4) << 2) | 0x03));
        for (uint8 i = 0; i < byteLen; i++) {
            result[i + 1] = bytes1(uint8(value >> (i * 8)));
        }
        return result;
    }
}
```

#### Vector encoding (Vec<T>)

```
compact(length) + encoded_item_0 + encoded_item_1 + ...

Ejemplo Vec de 3 instrucciones:
  0x0c = compact(3)
  [instrucción 0][instrucción 1][instrucción 2]
```

#### Option<T>

```
0x00 → None
0x01 + encoded(T) → Some(T)
```

---

### MultiLocation — Formato de bytes

MultiLocation es el sistema de direccionamiento de XCM. Toda dirección cross-chain se expresa como MultiLocation.

#### Estructura general

```
parents (u8) | interior (Junctions)
```

#### Junctions encoding

```
0x00 → Here (sin junctions)
0x01 → X1(junction)
0x02 → X2(junction, junction)
...hasta X8
```

#### Junction types más usados

```solidity
// Parachain(id) → 0x00 + compact(id)
// AccountId32(network, id) → 0x01 + network + 32-byte id
// AccountKey20(network, key) → 0x03 + network + 20-byte address
// PalletInstance(index) → 0x04 + u8(index)
// GeneralIndex(index) → 0x05 + compact(index)
```

#### Ejemplos concretos

```
// Hub propio: parents=0, Here
0x00 0x00

// Parachain(2034) — Hydration desde Hub:
// parents=1, X1(Parachain(2034))
0x01               ← parents: 1
0x01               ← X1
0x00               ← Parachain junction type
0xD2 1F 00 00      ← compact(2034) en little-endian... 
// NOTA: 2034 en compact two-byte = (2034 << 2) | 0x01 = 8137 = 0x1FC9
// little-endian → C9 1F
// Resultado: 01 01 00 C9 1F

// AccountId32 en Hydration (account = bytes32):
0x01               ← AccountId32 junction
0x00               ← NetworkId: Any
[32 bytes address] ← el accountId
```

#### Helper en MultiLocation.sol

```solidity
library MultiLocation {
    /// @notice parents=1, X1(Parachain(paraId)) — destino de Hub a parachain
    function parachain(uint32 paraId) internal pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(1),           // parents: 1
            uint8(1),           // X1
            uint8(0),           // Parachain junction
            ScaleEncoder.encodeCompact(paraId)
        );
    }

    /// @notice parents=0, X1(AccountId32(Any, accountId)) — recipient en destino
    function accountId32(bytes32 accountId) internal pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(0),           // parents: 0
            uint8(1),           // X1
            uint8(1),           // AccountId32 junction
            uint8(0),           // NetworkId: Any
            accountId           // 32-byte id
        );
    }

    /// @notice Asset location — token en Hub: parents=0, Here
    function here() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0), uint8(0));
    }
}
```

---

### XCM Instruction Encoding

#### Versioned XCM message structure

```
version_byte | compact(num_instructions) | instruction_0 | instruction_1 | ...

version bytes:
  0x02 = V2
  0x03 = V3
  0x04 = V4
  0x05 = V5  ← Polkadot Hub usa V5
```

#### Instruction enum indices (XCM V3/V4/V5)

| Index | Instruction |
|---|---|
| `0x00` | WithdrawAsset |
| `0x01` | ReserveAssetDeposited |
| `0x02` | ReceiveTeleportedAsset |
| `0x09` | ClearOrigin |
| `0x0A` | DescendOrigin |
| `0x0D` | DepositAsset |
| `0x10` | InitiateReserveWithdraw |
| `0x11` | InitiateTeleport |
| `0x13` | BuyExecution |
| `0x1F` | SetFeesMode |

#### Reserve transfer — instrucción sequence completa

Este es el patrón que `XCMProgram.sol` debe ensamblar para `transfer()`:

```
V5 prefix: 0x05
4 instructions: 0x10  (compact 4)

[0] WithdrawAsset (0x00)
    assets: Vec<MultiAsset> with 1 asset
      AssetId: Concrete(MultiLocation{ parents:0, interior:Here })
      Fungibility: Fungible(amount) — compact encoded

[1] ClearOrigin (0x09)
    no payload

[2] BuyExecution (0x13)
    fees: MultiAsset (same asset location)
    weight_limit: Unlimited (0x00) | Limited(weight) (0x01 + compact)

[3] DepositAsset (0x0D)
    assets: Wild(All) = 0x00 0x00
    beneficiary: MultiLocation of recipient
```

#### Ejemplo real de mensaje — decode del oficial

El mensaje de ejemplo en la doc oficial:
```
0x050c000401000003008c86471301000003008c8647000d010101000000010100368e...
```

Desglose:
```
05          ← XCM V5
0c          ← compact(3) = 3 instrucciones
00          ← WithdrawAsset
  04        ← 1 asset (compact 1)
  01        ← Concrete AssetId
  00 00     ← MultiLocation: parents=0, Here
  03        ← Fungible
  008c8647  ← compact amount
13          ← BuyExecution
  00        ← fee asset (same)
  ...
0d          ← DepositAsset
  01 01     ← Wild(AllOf{...}) or specific
  ...
```

**Referencia completa de XCM encoding:** https://github.com/polkadot-fellows/xcm-format

---

### XCMBridge.sol — Spec completo

El único contrato deployado. No usar OpenZeppelin — implementar patterns mínimos inline.

```solidity
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
    error UnsupportedDestination(uint32 paraId);

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
}
```

---

### Ignition deployment script

Crear en `contracts/ignition/modules/XCMBridge.ts`:

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const XCMBridgeModule = buildModule("XCMBridgeModule", (m) => {
  const xcmBridge = m.contract("XCMBridge", []);
  return { xcmBridge };
});

export default XCMBridgeModule;
```

Deploy command:
```bash
npx hardhat ignition deploy ./ignition/modules/XCMBridge.ts --network passetHub
```

---

### Test structure — ejemplos por library

Crear en `contracts/test/`:

#### test/ScaleEncoder.test.ts

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ScaleEncoder", function () {
  let encoder: any;

  before(async () => {
    // Deploy a test helper contract that exposes library functions
    const Factory = await ethers.getContractFactory("ScaleEncoderTest");
    encoder = await Factory.deploy();
  });

  describe("encodeU32", () => {
    it("encodes 0 as 4 zero bytes", async () => {
      expect(await encoder.encodeU32(0)).to.equal("0x00000000");
    });
    it("encodes 1 as little-endian", async () => {
      expect(await encoder.encodeU32(1)).to.equal("0x01000000");
    });
    it("encodes 2034 (Hydration paraId)", async () => {
      // 2034 = 0x7F2 → little-endian: F2 07 00 00
      expect(await encoder.encodeU32(2034)).to.equal("0xf2070000");
    });
  });

  describe("encodeCompact", () => {
    it("single-byte mode: 0", async () => {
      expect(await encoder.encodeCompact(0)).to.equal("0x00");
    });
    it("single-byte mode: 63", async () => {
      expect(await encoder.encodeCompact(63)).to.equal("0xfc");
    });
    it("two-byte mode: 64", async () => {
      // 64 << 2 | 1 = 257 = 0x0101 → LE: 01 01
      expect(await encoder.encodeCompact(64)).to.equal("0x0101");
    });
    it("encodes large token amount (1 DOT = 10^10)", async () => {
      const oneDot = BigInt("10000000000");
      const result = await encoder.encodeCompact(oneDot);
      expect(result).to.have.length.greaterThan(2); // multi-byte
    });
  });
});
```

#### test/MultiLocation.test.ts

```typescript
describe("MultiLocation", function () {
  describe("parachain()", () => {
    it("encodes Hydration (2034) correctly", async () => {
      const result = await multiLocation.parachain(2034);
      // parents=1 (0x01), X1 (0x01), Parachain (0x00), compact(2034)
      expect(result.slice(0, 6)).to.equal("0x010100");
    });
    it("encodes AssetHub (1000)", async () => {
      const result = await multiLocation.parachain(1000);
      expect(result.slice(0, 6)).to.equal("0x010100");
    });
  });
});
```

#### test/XCMKit.integration.test.ts (Passet Hub testnet)

```typescript
// Run with: npx hardhat test --network passetHub
describe("XCMKit integration", function () {
  this.timeout(60_000); // testnet calls take time

  it("weighMessage returns non-zero weight for valid XCM", async () => {
    const xcm = await ethers.getContractAt(
      "IXcm",
      "0x00000000000000000000000000000000000a0000"
    );
    // Known-good encoded XCM from official docs
    const message = "0x050c000401000003008c86471301000003008c8647000d010101000000010100368e8759910dab756d344995f1d3c79374ca8f70066d3a709e48029f6bf0ee7e";
    const weight = await xcm.weighMessage(message);
    expect(weight.refTime).to.be.gt(0);
    expect(weight.proofSize).to.be.gt(0);
  });
});
```

---

### Playground — componentes y estructura

```
playground/src/
├── components/
│   ├── TransferForm.tsx      ← formulario principal
│   ├── FeeEstimate.tsx       ← preview de fee antes de transferir
│   ├── TxStatus.tsx          ← estado de la tx + link Blockscout
│   ├── XCMTracker.tsx        ← embed de Ocelloids tracker
│   └── WalletConnect.tsx     ← MetaMask / Talisman connect
├── lib/
│   ├── contract.ts           ← ABI + contract instance
│   ├── chains.ts             ← PASSET_HUB config + Destination presets
│   └── format.ts             ← formatAddress, formatAmount helpers
└── App.tsx
```

#### lib/chains.ts

```typescript
export const PASSET_HUB = {
  chainId: 420420422,
  chainIdHex: "0x1911f0a6",
  name: "Passet Hub",
  rpcUrl: "https://testnet-passet-hub-eth-rpc.polkadot.io",
  blockExplorer: "https://blockscout-passet-hub.parity-testnet.parity.io",
  currency: "PAS",
  faucet: "https://faucet.polkadot.io/?parachain=1111",
};

export const DESTINATIONS = [
  { label: "Hydration",    paraId: 2034 },
  { label: "Moonbeam",     paraId: 2004 },
  { label: "Astar",        paraId: 2006 },
  { label: "Acala",        paraId: 2000 },
  { label: "Bifrost",      paraId: 2030 },
  { label: "AssetHub",     paraId: 1000 },
] as const;

export const XCMTRACKER_URL = "https://xcm-tracker.ocelloids.net";
```

#### TransferForm.tsx — flujo de usuario

```
1. Usuario selecciona destination del dropdown (DESTINATIONS)
2. Ingresa token address (o selecciona de preset)
3. Ingresa amount
4. Ingresa recipient address
5. Click "Estimate Fee" → llama estimateFee(), muestra FeeEstimate
6. Click "Transfer" → llama transfer(), muestra TxStatus
7. TxStatus muestra hash + link a Blockscout + embed XCMTracker
```

---

### OpenZeppelin — corrección

El AGENTS.md de Kitdot indica claramente:

> *"Avoid OpenZeppelin (causes size issues)"*
> *"Remove OpenZeppelin dependencies"*

Existe una versión size-optimizada para Polkadot: `papermoonio/openzeppelin-contracts-polkadot`, pero agrega complejidad de setup que no vale para un solo contrato demo.

**Para XCMBridge.sol usar los patterns inline documentados arriba:** `onlyOwner` custom + `nonReentrant` custom. Son 10 líneas y no tienen dependencias.

Si en el futuro el proyecto escala y necesita más contratos, evaluar `papermoonio/openzeppelin-contracts-polkadot`.

---

### Setup completo — paso a paso

```bash
# 1. Inicializar con kitdot (recomendado)
npm install -g kitdot
kitdot init xcmkit
cd xcmkit

# 2. Private key (sin prefijo 0x)
npx hardhat vars set PRIVATE_KEY

# 3. Obtener PAS tokens para deploy
# https://faucet.polkadot.io/?parachain=1111

# 4. Compilar
npx hardhat compile

# 5. Tests locales
npx hardhat test

# 6. Deploy a Passet Hub
npx hardhat ignition deploy ./ignition/modules/XCMBridge.ts --network passetHub

# 7. Verificar tamaño del contrato
npx hardhat size-contracts

# 8. Tests de integración (necesita PAS tokens)
npx hardhat test --network passetHub

# 9. Frontend
cd playground
npm install
npm run dev
```

### Errores y fixes completos

| Error | Causa exacta | Fix |
|---|---|---|
| `CodeRejected` | Falta `polkavm: true` en network o falta `resolc` block | Agregar ambos a hardhat.config.ts |
| `initcode is too big` | Contrato > 100KB | Usar library pattern, eliminar OZ estándar, `npx hardhat size-contracts` |
| `Cannot read properties of undefined (reading 'version')` | Solidity como objeto `{version: "0.8.28"}` | Cambiar a string: `solidity: "0.8.28"` |
| `No signers found` | PRIVATE_KEY no seteada | `npx hardhat vars set PRIVATE_KEY` (sin 0x prefix) |
| `XCM execution failed: Barrier` | XCM message malformado o fee insuficiente | Verificar SCALE encoding, llamar `weighMessage` antes de `execute` |
| `Precompile call reverted` | Amount 0 o destino sin HRMP channel abierto | Verificar que Hub↔destino tenga canal HRMP activo |
| `insufficient funds` | Sin PAS en cuenta | Faucet: https://faucet.polkadot.io/?parachain=1111 |

### Referencias de implementación

- **IXcm.sol fuente oficial:** https://github.com/paritytech/polkadot-sdk/blob/master/polkadot/xcm/pallet-xcm/src/precompiles/IXcm.sol
- **XCM format spec (instrucciones + encoding):** https://github.com/polkadot-fellows/xcm-format
- **SCALE codec docs:** https://docs.polkadot.com/polkadot-protocol/parachain-basics/data-encoding
- **XCM gist con ejemplos reales en Passet Hub:** https://gist.github.com/franciscoaguirre/a6dea0c55e81faba65bedf700033a1a2
- **PAPI console para inspeccionar XCM:** https://dev.papi.how/extrinsics
- **Ocelloids XCM Tracker:** https://xcm-tracker.ocelloids.net
- **Blockscout Passet Hub:** https://blockscout-passet-hub.parity-testnet.parity.io

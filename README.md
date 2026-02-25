# XCMKit

> The first Solidity library for on-chain XCM execution on Polkadot Hub.

**Polkadot Solidity Hackathon 2026 | Track 2: PVM Smart Contracts**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🌟 Overview

XCMKit is an open-source Solidity library that abstracts the raw XCM precompile on Polkadot Hub into a developer-friendly API. Any smart contract can import XCMKit and execute cross-chain transfers, send XCM messages, and compose XCM programs — with no external dependencies, no off-chain infrastructure, and no user interaction required.

**Key Features:**
- ✅ Pure Solidity library — no off-chain dependencies
- ✅ SCALE encoding built-in
- ✅ MultiLocation construction helpers
- ✅ Weight estimation via precompile
- ✅ Support for reserve transfers, teleports, and Snowbridge
- ✅ One-line cross-chain transfers

## 📐 Architecture

```
Your Contract
     ↓
XCMKit Library (Solidity)
    ├── ScaleEncoder.sol
    ├── MultiLocation.sol
    ├── XCMProgram.sol
    └── WeightHelper.sol
     ↓
IXcm Precompile (0xA0000)
```

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/carlos-israelj/XCMKit.git
cd XCMKit

# Install contracts dependencies
cd contracts
npm install

# Compile contracts
npm run compile
```

### Basic Usage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./libs/XCMKit.sol";
import "./libs/MultiLocation.sol";

contract MyContract {
    function transferToHydration() external {
        XCMKit.transfer(
            MultiLocation.HYDRATION,          // destination parachain
            0x1234...5678,                    // recipient address
            address(0),                       // native token (PAS)
            1000000000000000000              // amount (1 token)
        );
    }
}
```

### With Fee Control

```solidity
function transferWithFeeLimit() external {
    XCMKit.transferWithFee(
        MultiLocation.MOONBEAM,
        recipient,
        token,
        amount,
        maxFee  // explicit fee cap
    );
}
```

### Fee Estimation

```solidity
function estimateTransferCost() external view returns (uint256) {
    (, uint256 fee) = XCMKit.estimateFee(
        MultiLocation.ASTAR,
        token,
        amount
    );
    return fee;
}
```

## 🎯 Supported Chains (v1)

| Chain | Parachain ID | Type |
|-------|-------------|------|
| AssetHub | 1000 | System chain (teleport supported) |
| BridgeHub | 1002 | System chain (teleport supported) |
| Acala | 2000 | Parachain |
| Moonbeam | 2004 | Parachain |
| Astar | 2006 | Parachain |
| Bifrost | 2030 | Parachain |
| Hydration | 2034 | Parachain |

## 📝 API Reference

### XCMKit Library

```solidity
library XCMKit {
    // Transfer tokens to destination parachain
    function transfer(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) internal;

    // Transfer with explicit fee cap
    function transferWithFee(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount,
        uint256 maxFee
    ) internal;

    // Teleport for trusted system chains
    function teleport(
        uint32 destinationParaId,
        address recipient,
        address token,
        uint256 amount
    ) internal;

    // Estimate transfer fee
    function estimateFee(
        uint32 destinationParaId,
        address token,
        uint256 amount
    ) internal view returns (IXcm.Weight memory, uint256);
}
```

## 💡 Use Cases

### Autonomous DeFi Rebalancing

```solidity
contract LiquidityRouter {
    function rebalance() external {
        if (hydrationAPY > localAPY + threshold) {
            XCMKit.transfer(Destination.HYDRATION, pool, DOT, liquidity);
        }
    }
}
```

### Cross-Chain Vesting

```solidity
contract VestingSchedule {
    function release() external {
        require(block.timestamp >= vestingEnd);
        uint256 amount = IERC20(dotToken).balanceOf(address(this));
        XCMKit.transfer(Destination.ASTAR, beneficiary, dotToken, amount);
    }
}
```

## 🛠️ Tech Stack

- Solidity 0.8.28
- Hardhat + @parity/hardhat-polkadot
- PolkaVM (resolc 0.3.0)
- Zero external dependencies

## 📦 Project Structure

```
xcmkit/
├── contracts/              # XCMKit library + demo contract
│   ├── contracts/
│   │   ├── XCMBridge.sol      # Demo coordinator contract
│   │   ├── libs/              # XCMKit libraries
│   │   │   ├── XCMKit.sol
│   │   │   ├── ScaleEncoder.sol
│   │   │   ├── MultiLocation.sol
│   │   │   ├── XCMProgram.sol
│   │   │   └── WeightHelper.sol
│   │   └── interfaces/
│   │       └── IXcm.sol
│   ├── test/
│   └── ignition/modules/
│
├── playground/            # Demo frontend (minimal React app)
│   ├── src/
│   └── package.json
│
├── LICENSE
└── README.md
```

## 🧪 Testing

```bash
cd contracts
npm test
```

Tests cover:
- SCALE encoding
- MultiLocation construction
- XCM program assembly
- Weight estimation
- Contract integration

## 📋 Deploy to Passet Hub

```bash
# Set your private key
npx hardhat vars set PRIVATE_KEY

# Get PAS tokens
# https://faucet.polkadot.io/?parachain=1111

# Deploy
npm run deploy:testnet

# Verify contract size
npx hardhat size-contracts
```

## 🔗 Resources

- [XCM Precompile Documentation](https://docs.polkadot.com/develop/smart-contracts/precompiles/xcm-precompile/)
- [SCALE Codec Specification](https://docs.polkadot.com/polkadot-protocol/parachain-basics/data-encoding)
- [XCM Format Spec](https://github.com/polkadot-fellows/xcm-format)
- [Architecture Document](./XCMKit_Architecture_v2.md)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🏆 Hackathon Submission

This project was created for the Polkadot Solidity Hackathon 2026, Track 2: PVM Smart Contracts.

**Deliverable:** A production-ready Solidity library for on-chain XCM execution + interactive playground demo

**Team**: Carlos Israel Jiménez

---

Built for the Polkadot ecosystem

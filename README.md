# XCMBridge & XCMKit

> Cross-chain transfers on Polkadot Hub — one click, no seed phrases, no XCM knowledge required.

**Polkadot Solidity Hackathon 2026 | Track 2: PVM Smart Contracts**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🌟 Overview

XCMBridge is a cross-chain transfer application built on Polkadot Hub, powered by **XCMKit** — an open-source Solidity library that abstracts the XCM precompile into a developer-friendly API.

- **For Users**: Transfer tokens across parachains with social login (Google, GitHub, Discord, Twitter) — no wallet setup required
- **For Developers**: Simple Solidity API for XCM cross-chain transfers — no SCALE encoding, no MultiLocation complexity

## 📐 Architecture

```
XCMBridge Frontend (React + Web3Auth)
         ↓
XCMBridge.sol (Coordinator Contract)
         ↓
XCMKit Library (Solidity)
    ├── ScaleEncoder.sol
    ├── MultiLocation.sol
    ├── XCMProgram.sol
    └── WeightHelper.sol
         ↓
IXcm Precompile (0x...0a0000)
```

## 🚀 Quick Start

### Prerequisites

- Node.js >= 18
- Git

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

# Run tests
npm test
```

### Deploy to Passet Hub Testnet

```bash
# Set your private key in contracts/.env
echo "PRIVATE_KEY=your_private_key_here" > contracts/.env

# Deploy
cd contracts
npm run deploy:testnet
```

## 💻 Usage Examples

### Basic Transfer

```solidity
import "./libs/XCMKit.sol";
import "./libs/MultiLocation.sol";

contract MyContract {
    using XCMKit for *;

    function transferToHydration() external {
        XCMKit.transfer(
            MultiLocation.HYDRATION,          // destination parachain
            0x1234...5678,                    // recipient address
            address(dotToken),                // token to transfer
            1000000000000000000              // amount (1 DOT)
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

## 🛠️ Tech Stack

### Contracts
- Solidity 0.8.28
- Hardhat + @parity/hardhat-polkadot
- PolkaVM (resolc 0.3.0)
- OpenZeppelin Contracts

### Frontend
- React 18 + Vite + TypeScript
- Tailwind CSS
- ethers.js v6
- wagmi
- Web3Auth MPC

## 📦 Project Structure

```
xcmbridge/
├── contracts/              # Smart contracts
│   ├── contracts/
│   │   ├── XCMBridge.sol      # Main contract
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
├── frontend/              # React application
│   ├── src/
│   │   ├── components/
│   │   └── hooks/
│   └── package.json
│
├── LICENSE
└── README.md
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

## 🧪 Testing

```bash
cd contracts
npm test
```

Tests cover:
- Contract deployment
- Validation logic
- Fee estimation interface
- Multi-chain support
- SCALE encoding (unit tests)

## 🔗 Resources

- [XCM Precompile Documentation](https://docs.polkadot.com/develop/smart-contracts/precompiles/xcm-precompile/)
- [SCALE Codec Specification](https://docs.substrate.io/reference/scale-codec/)
- [Polkadot Hackathon Guide](https://github.com/polkadot-developers/hackathon-guide)
- [Architecture Document](./XCMKit_Architecture_v2.md)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🏆 Hackathon Submission

This project was created for the Polkadot Solidity Hackathon 2026, Track 2: PVM Smart Contracts.

**Team**: Carlos Israel Jiménez

---

Built with ❤️ for the Polkadot ecosystem

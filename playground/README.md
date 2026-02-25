# XCMKit Playground

Interactive demo interface for testing XCMKit cross-chain transfers on Polkadot.

## Features

- ✅ MetaMask wallet connection
- ✅ Destination chain selector (7 supported chains)
- ✅ Amount input with recipient address
- ✅ Fee estimation preview
- ✅ Transfer execution (reserve transfer & teleport)
- ✅ Responsive design

## Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## Supported Chains

- **AssetHub** (1000) - System chain (teleport)
- **BridgeHub** (1002) - System chain (teleport)
- **Acala** (2000) - Parachain
- **Moonbeam** (2004) - Parachain
- **Astar** (2006) - Parachain
- **Bifrost** (2030) - Parachain
- **Hydration** (2034) - Parachain

## Configuration

Update `src/config.ts` with your deployed contract address once available.

## Demo Mode

Currently in demo mode. Once XCMBridge is deployed to Passet Hub testnet, the interface will execute real transactions.

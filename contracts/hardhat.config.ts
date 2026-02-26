// WebSocket polyfill must be loaded BEFORE any polkadot imports
import { WebSocket } from 'ws';
if (typeof global.WebSocket === 'undefined') {
  (global as any).WebSocket = WebSocket;
}
if (typeof globalThis.WebSocket === 'undefined') {
  (globalThis as any).WebSocket = WebSocket;
}

import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-viem";
import "@parity/hardhat-polkadot";
import dotenv from "dotenv";

dotenv.config();

const privateKey = process.env.PRIVATE_KEY;
if (!privateKey) {
  console.warn(
    "⚠️  WARNING: PRIVATE_KEY environment variable not found. Please set it in your .env file for network deployments."
  );
}

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  resolc: {
    version: "0.3.0",
    compilerSource: "npm",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
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
      accounts: privateKey ? [privateKey] : [],
    },
  },
};

export default config;

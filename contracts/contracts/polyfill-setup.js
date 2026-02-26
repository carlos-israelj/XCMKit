// WebSocket polyfill for Node.js environment
// Required by @parity/hardhat-polkadot plugin

const { WebSocket } = require('ws');

// Set WebSocket on global object
if (typeof global.WebSocket === 'undefined') {
  global.WebSocket = WebSocket;
}

// Also set on globalThis for compatibility
if (typeof globalThis.WebSocket === 'undefined') {
  globalThis.WebSocket = WebSocket;
}

module.exports = WebSocket;

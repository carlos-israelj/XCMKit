export const SUPPORTED_CHAINS = [
  { id: 1000, name: 'AssetHub', type: 'system' },
  { id: 1002, name: 'BridgeHub', type: 'system' },
  { id: 2000, name: 'Acala', type: 'parachain' },
  { id: 2004, name: 'Moonbeam', type: 'parachain' },
  { id: 2006, name: 'Astar', type: 'parachain' },
  { id: 2030, name: 'Bifrost', type: 'parachain' },
  { id: 2034, name: 'Hydration', type: 'parachain' },
] as const;

export const CONTRACT_ADDRESS = '0x0000000000000000000000000000000000000000'; // To be deployed
export const RPC_URL = 'https://testnet-passet-hub-eth-rpc.polkadot.io';

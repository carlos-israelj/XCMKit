import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { SUPPORTED_CHAINS, CONTRACT_ADDRESS, RPC_URL } from './config'
import './App.css'

// XCMBridge ABI (simplified for demo)
const XCM_BRIDGE_ABI = [
  'function transfer(uint32 destinationParaId, address recipient, address token, uint256 amount) external',
  'function teleport(uint32 destinationParaId, address recipient, address token, uint256 amount) external',
  'function estimateFee(uint32 destinationParaId, address token, uint256 amount) external view returns (uint256)',
  'function getSupportedChains() external view returns (uint32[])',
]

interface TransferForm {
  destinationChainId: number
  recipient: string
  tokenAddress: string
  amount: string
}

function App() {
  const [account, setAccount] = useState<string>('')
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null)
  const [form, setForm] = useState<TransferForm>({
    destinationChainId: 2034, // Default to Hydration
    recipient: '',
    tokenAddress: '0x0000000000000000000000000000000000000001',
    amount: '',
  })
  const [estimatedFee, setEstimatedFee] = useState<string>('')
  const [loading, setLoading] = useState(false)
  const [txHash, setTxHash] = useState<string>('')
  const [error, setError] = useState<string>('')

  useEffect(() => {
    checkWalletConnection()
  }, [])

  const checkWalletConnection = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum)
        setProvider(provider)
        
        const accounts = await provider.listAccounts()
        if (accounts.length > 0) {
          setAccount(accounts[0].address)
        }
      } catch (err) {
        console.error('Failed to check wallet connection:', err)
      }
    }
  }

  const connectWallet = async () => {
    if (typeof window.ethereum === 'undefined') {
      setError('MetaMask is not installed')
      return
    }

    try {
      setLoading(true)
      setError('')
      const provider = new ethers.BrowserProvider(window.ethereum)
      await provider.send('eth_requestAccounts', [])
      const signer = await provider.getSigner()
      const address = await signer.getAddress()
      setAccount(address)
      setProvider(provider)
    } catch (err: any) {
      setError(err.message || 'Failed to connect wallet')
    } finally {
      setLoading(false)
    }
  }

  const estimateFeeHandler = async () => {
    if (!provider || !form.amount) return

    try {
      setLoading(true)
      setError('')
      
      // In production, this would call the actual contract
      // For demo, we'll show a placeholder
      const amountInWei = ethers.parseEther(form.amount)
      const estimatedFeeWei = amountInWei / 10n // Estimate 10% fee
      setEstimatedFee(ethers.formatEther(estimatedFeeWei))
    } catch (err: any) {
      setError(err.message || 'Failed to estimate fee')
    } finally {
      setLoading(false)
    }
  }

  const handleTransfer = async () => {
    if (!provider || !account) {
      setError('Please connect your wallet')
      return
    }

    if (!form.recipient || !form.amount) {
      setError('Please fill in all fields')
      return
    }

    try {
      setLoading(true)
      setError('')
      setTxHash('')

      const signer = await provider.getSigner()
      const contract = new ethers.Contract(CONTRACT_ADDRESS, XCM_BRIDGE_ABI, signer)

      const selectedChain = SUPPORTED_CHAINS.find(c => c.id === form.destinationChainId)
      const amountInWei = ethers.parseEther(form.amount)

      let tx
      if (selectedChain?.type === 'system') {
        // Use teleport for system chains
        tx = await contract.teleport(
          form.destinationChainId,
          form.recipient,
          form.tokenAddress,
          amountInWei
        )
      } else {
        // Use reserve transfer for parachains
        tx = await contract.transfer(
          form.destinationChainId,
          form.recipient,
          form.tokenAddress,
          amountInWei
        )
      }

      setTxHash(tx.hash)
      await tx.wait()
      
      // Reset form
      setForm({ ...form, recipient: '', amount: '' })
      setEstimatedFee('')
    } catch (err: any) {
      setError(err.message || 'Transaction failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="app">
      <header className="header">
        <h1>XCMKit Playground</h1>
        <p>Cross-chain transfers on Polkadot</p>
      </header>

      <main className="main">
        {!account ? (
          <div className="connect-card">
            <h2>Connect Wallet</h2>
            <p>Connect your MetaMask wallet to start using XCMKit</p>
            <button 
              onClick={connectWallet} 
              disabled={loading}
              className="btn-primary"
            >
              {loading ? 'Connecting...' : 'Connect MetaMask'}
            </button>
          </div>
        ) : (
          <div className="transfer-card">
            <div className="account-info">
              <span className="label">Connected:</span>
              <span className="address">{account.slice(0, 6)}...{account.slice(-4)}</span>
            </div>

            <form className="transfer-form" onSubmit={(e) => { e.preventDefault(); handleTransfer(); }}>
              <div className="form-group">
                <label>Destination Chain</label>
                <select
                  value={form.destinationChainId}
                  onChange={(e) => setForm({ ...form, destinationChainId: Number(e.target.value) })}
                  className="select"
                >
                  {SUPPORTED_CHAINS.map(chain => (
                    <option key={chain.id} value={chain.id}>
                      {chain.name} ({chain.type})
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Recipient Address</label>
                <input
                  type="text"
                  value={form.recipient}
                  onChange={(e) => setForm({ ...form, recipient: e.target.value })}
                  placeholder="0x..."
                  className="input"
                />
              </div>

              <div className="form-group">
                <label>Token Address</label>
                <input
                  type="text"
                  value={form.tokenAddress}
                  onChange={(e) => setForm({ ...form, tokenAddress: e.target.value })}
                  placeholder="0x..."
                  className="input"
                />
              </div>

              <div className="form-group">
                <label>Amount (in tokens)</label>
                <input
                  type="text"
                  value={form.amount}
                  onChange={(e) => {
                    setForm({ ...form, amount: e.target.value })
                    setEstimatedFee('')
                  }}
                  placeholder="0.0"
                  className="input"
                />
              </div>

              {form.amount && (
                <button
                  type="button"
                  onClick={estimateFeeHandler}
                  disabled={loading}
                  className="btn-secondary"
                >
                  Estimate Fee
                </button>
              )}

              {estimatedFee && (
                <div className="fee-estimate">
                  <span className="label">Estimated Fee:</span>
                  <span className="value">{estimatedFee} PAS</span>
                </div>
              )}

              {error && (
                <div className="error-message">
                  {error}
                </div>
              )}

              {txHash && (
                <div className="success-message">
                  Transaction submitted! Hash: {txHash.slice(0, 10)}...
                </div>
              )}

              <button
                type="submit"
                disabled={loading || !form.recipient || !form.amount}
                className="btn-primary"
              >
                {loading ? 'Processing...' : 'Transfer'}
              </button>
            </form>

            <div className="info-box">
              <h3>ℹ️ Demo Mode</h3>
              <p>This is a demo interface. Contract deployment pending.</p>
              <p>Once deployed to Passet Hub testnet, you'll be able to execute real cross-chain transfers.</p>
            </div>
          </div>
        )}
      </main>

      <footer className="footer">
        <p>Powered by XCMKit | Polkadot Hackathon 2026</p>
      </footer>
    </div>
  )
}

export default App

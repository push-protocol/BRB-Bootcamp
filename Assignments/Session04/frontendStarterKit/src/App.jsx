import { useState } from "react";
import pushLogo from "./assets/push.svg";
import "./App.css";
import { ethers } from "ethers";

import counterAbi from "./abis/counterAbi.json";
const contractAddress = "0x312319c3f8311EbFca17392c7A5Fef674a48Fa72";

function App() {
  const [count, setCount] = useState(0);
  const [address, setAddress] = useState();
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();

  const connectWallet = async () => { };

  const disconnectWallet = async () => { };

  const switchChain = async (chainId) => { };

  const getCounter = async () => { };

  const incrementCounter = async () => { };

  const decrementCounter = async () => { };

  return (
    <>
      <a href="https://push.org" target="_blank" rel="noopener noreferrer">
        <img src={pushLogo} className="logo" alt="Push logo" />
      </a>
      <h1>BRB Session 4</h1>
      <div className="wallet">
        {!address ? (
          <button onClick={connectWallet}>Connect Wallet</button>
        ) : (
          <div>
            <button onClick={disconnectWallet}>Disconnect Wallet</button>
            <h3>Address: {address}</h3>
          </div>
        )}
      </div>
      <div className="flex-body">
        <button onClick={() => switchChain(1)}>Switch to Mainnet</button>
        <button onClick={() => switchChain(11155111)}>Switch to Sepolia</button>
      </div>

      <div className="card">
        <div>
          <button onClick={getCounter}>Get Counter Value</button>
          {count !== undefined && <h4>Counter Value: {count}</h4>}
        </div>
        <div className="flex-body">
          <button onClick={incrementCounter}>Increment Counter</button>
          <button onClick={decrementCounter}>Decrement Counter</button>
        </div>
      </div>
    </>
  );
}

export default App;

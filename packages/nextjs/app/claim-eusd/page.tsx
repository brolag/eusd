"use client";

import { useState } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount, useBalance } from "wagmi";

const Claim = () => {
  const { address: connectedAddress, isConnected } = useAccount();
  const { data: ethBalance } = useBalance({ address: connectedAddress });
  const [claimAmount, setClaimAmount] = useState("");

  const handleClaim = () => {
    // Implement claim logic here
    console.log(`Claiming ${claimAmount} ETH`);
  };

  return (
    <>
      {isConnected ? (
        <div className="bg-white/10 rounded-lg p-6 max-w-md mx-auto">
          <h2 className="text-xl font-semibold mb-4">Claim ETH</h2>
          <div className="mb-4">
            <p className="text-sm opacity-70">Your ETH Balance</p>
            <p className="text-2xl font-bold">{ethBalance?.formatted} ETH</p>
          </div>
          <div className="mb-4">
            <label htmlFor="claimAmount" className="block text-sm font-medium mb-2">
              Amount to Claim
            </label>
            <div className="relative">
              <input
                type="number"
                id="claimAmount"
                className="w-full px-3 py-2 bg-white/5 rounded-md text-white"
                placeholder="0.0"
                value={claimAmount}
                onChange={e => setClaimAmount(e.target.value)}
              />
              <span className="absolute right-3 top-2 text-sm opacity-70">ETH</span>
            </div>
          </div>
          <button
            onClick={handleClaim}
            className="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
            type="button"
          >
            Claim
          </button>
        </div>
      ) : (
        <div className="text-center py-20">
          <h1 className="text-4xl font-bold mb-4">Connect to Claim</h1>
          <p className="text-xl mb-8">Please connect your wallet to make a claim</p>
          <ConnectButton />
        </div>
      )}
    </>
  );
};

export default Claim;

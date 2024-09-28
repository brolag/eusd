"use client";

import { useState } from "react";
import Link from "next/link";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount, useBalance } from "wagmi";
import { ArrowLeftIcon } from "@heroicons/react/24/outline";

const Deposit = () => {
  const { address: connectedAddress, isConnected } = useAccount();
  const { data: ethBalance } = useBalance({ address: connectedAddress });
  const [depositAmount, setDepositAmount] = useState("");

  const handleDeposit = () => {
    // Implement deposit logic here
    console.log(`Depositing ${depositAmount} ETH`);
  };

  return (
    <>
      <Link href="/" className="absolute top-4 left-4 p-2 text-primary hover:bg-secondary rounded-full">
        <ArrowLeftIcon className="h-6 w-6" />
      </Link>
      {isConnected ? (
        <div className="bg-white/10 rounded-lg p-6 max-w-md mx-auto">
          <h2 className="text-xl font-semibold mb-4">Deposit ETH</h2>
          <div className="mb-4">
            <p className="text-sm opacity-70">Your ETH Balance</p>
            <p className="text-2xl font-bold">{ethBalance?.formatted} ETH</p>
          </div>
          <div className="mb-4">
            <label htmlFor="depositAmount" className="block text-sm font-medium mb-2">
              Amount to Deposit
            </label>
            <div className="relative">
              <input
                type="number"
                id="depositAmount"
                className="w-full px-3 py-2 bg-white/5 rounded-md text-white"
                placeholder="0.0"
                value={depositAmount}
                onChange={e => setDepositAmount(e.target.value)}
              />
              <span className="absolute right-3 top-2 text-sm opacity-70">ETH</span>
            </div>
          </div>
          <button
            onClick={handleDeposit}
            className="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
            type="button"
          >
            Deposit
          </button>
        </div>
      ) : (
        <div className="text-center py-20">
          <h1 className="text-4xl font-bold mb-4">Connect to Deposit</h1>
          <p className="text-xl mb-8">Please connect your wallet to make a deposit</p>
          <ConnectButton />
        </div>
      )}
    </>
  );
};

export default Deposit;

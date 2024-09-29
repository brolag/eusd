"use client";

import { useState } from "react";
import Link from "next/link";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount, useBalance } from "wagmi";
import { ArrowLeftIcon } from "@heroicons/react/24/outline";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { parseEther } from "viem";

const BurnEUSD = () => {
  const { address: connectedAddress, isConnected } = useAccount();
  const { data: eusdBalance } = useBalance({ address: connectedAddress, token: "0xYourEUSDTokenAddress" });
  const [burnAmount, setBurnAmount] = useState("");

  const { writeContractAsync: writeYourContractAsync } = useScaffoldWriteContract("EncodeStableCoin");


  const handleBurn = async() => {
    console.log(`Burning ${burnAmount} EUSD`);

    try {
      const tx = await writeYourContractAsync({
        functionName: "burn",
        args: [parseEther(burnAmount)],
      });

      console.log("Transaction sent:", tx);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <>
      <Link href="/" className="absolute top-4 left-4 p-2 text-primary hover:bg-secondary rounded-full">
        <ArrowLeftIcon className="h-6 w-6" />
      </Link>
      {isConnected ? (
        <div className="bg-white/10 rounded-lg p-6 max-w-md mx-auto">
          <h2 className="text-xl font-semibold mb-4">Burn EUSD</h2>
          <div className="mb-4">
            <p className="text-sm opacity-70">Your EUSD Balance</p>
            <p className="text-2xl font-bold">{eusdBalance?.formatted} EUSD</p>
          </div>
          <div className="mb-4">
            <label htmlFor="burnAmount" className="block text-sm font-medium mb-2">
              Amount to Burn
            </label>
            <div className="relative">
              <input
                type="number"
                id="burnAmount"
                className="w-full px-3 py-2 bg-white/5 rounded-md text-white"
                placeholder="0.0"
                value={burnAmount}
                onChange={e => setBurnAmount(e.target.value)}
              />
              <span className="absolute right-3 top-2 text-sm opacity-70">EUSD</span>
            </div>
          </div>
          <button
            onClick={handleBurn}
            className="w-full bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded"
            type="button"
          >
            Burn EUSD
          </button>
        </div>
      ) : (
        <div className="text-center py-20">
          <h1 className="text-4xl font-bold mb-4">Connect to Burn EUSD</h1>
          <p className="text-xl mb-8">Please connect your wallet to burn EUSD</p>
          <ConnectButton />
        </div>
      )}
    </>
  );
};

export default BurnEUSD;

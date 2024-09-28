"use client";

import { useEffect, useState } from "react";
import { useAccount, useBalance } from "wagmi";
import { BellIcon } from "@heroicons/react/24/outline";

const Home = () => {
  const { address: connectedAddress, isConnected } = useAccount();
  const { data: ethBalance } = useBalance({ address: connectedAddress });
  const [ethPrice, setEthPrice] = useState(0);
  const [eusdRate, setEusdRate] = useState(0);

  useEffect(() => {
    setEthPrice(1800);
    setEusdRate(1800 * 0.8);
  }, []);

  return (
    <>
      {isConnected ? (
        <>
          <div className="bg-white/10 rounded-lg p-6 mb-6">
            <h2 className="text-xl font-semibold mb-4">Your Balances</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-white/5 p-4 rounded-md">
                <p className="text-sm opacity-70">ETH Balance</p>
                <p className="text-2xl font-bold">{ethBalance?.formatted} ETH</p>
              </div>
              <div className="bg-white/5 p-4 rounded-md">
                <p className="text-sm opacity-70">EUSD Balance</p>
                <p className="text-2xl font-bold">0 EUSD</p>
              </div>
            </div>
          </div>

          <div className="bg-white/10 rounded-lg p-6 mb-6">
            <h2 className="text-xl font-semibold mb-4">Market Data</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-white/5 p-4 rounded-md">
                <p className="text-sm opacity-70">ETH Price</p>
                <p className="text-2xl font-bold">${ethPrice.toFixed(2)}</p>
              </div>
              <div className="bg-white/5 p-4 rounded-md">
                <p className="text-sm opacity-70">EUSD Conversion Rate</p>
                <p className="text-2xl font-bold">1 EUSD = ${eusdRate.toFixed(2)}</p>
              </div>
            </div>
          </div>

          <div className="bg-yellow-500/20 border border-yellow-500 rounded-lg p-4 mb-6 flex items-center">
            <BellIcon className="h-6 w-6 mr-2" />
            <p>Your current collateralization ratio is healthy.</p>
          </div>
        </>
      ) : (
        <div className="text-center py-20">
          <h1 className="text-4xl font-bold mb-4">Welcome to EUSD</h1>
          <p className="text-xl mb-8">Connect your wallet to get started</p>
        </div>
      )}
    </>
  );
};

export default Home;

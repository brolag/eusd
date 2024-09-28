"use client";

import { useState } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";

const mockTransactions = [
  { id: 1, type: "Deposit", amount: "1.5 ETH", date: "2023-05-01", status: "Completed" },
  { id: 2, type: "Withdraw", amount: "0.5 ETH", date: "2023-05-03", status: "Completed" },
  { id: 3, type: "Claim EUSD", amount: "100 EUSD", date: "2023-05-05", status: "Pending" },
  { id: 4, type: "Deposit", amount: "2.0 ETH", date: "2023-05-07", status: "Completed" },
  { id: 5, type: "Withdraw", amount: "1.0 ETH", date: "2023-05-10", status: "Failed" },
];

const TransactionHistory = () => {
  const { isConnected } = useAccount();
  const [transactions] = useState(mockTransactions);

  return (
    <>
      {isConnected ? (
        <div className="bg-white/10 rounded-lg p-6 max-w-4xl mx-auto">
          <h2 className="text-2xl font-semibold mb-6">Transaction History</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="text-left border-b border-white/20">
                  <th className="pb-2">Type</th>
                  <th className="pb-2">Amount</th>
                  <th className="pb-2">Date</th>
                  <th className="pb-2">Status</th>
                </tr>
              </thead>
              <tbody>
                {transactions.map(tx => (
                  <tr key={tx.id} className="border-b border-white/10">
                    <td className="py-3">{tx.type}</td>
                    <td className="py-3">{tx.amount}</td>
                    <td className="py-3">{tx.date}</td>
                    <td className="py-3">
                      <span
                        className={`px-2 py-1 rounded ${
                          tx.status === "Completed"
                            ? "bg-green-500/20 text-green-300"
                            : tx.status === "Pending"
                            ? "bg-yellow-500/20 text-yellow-300"
                            : "bg-red-500/20 text-red-300"
                        }`}
                      >
                        {tx.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="text-center py-20">
          <h1 className="text-4xl font-bold mb-4">Connect to View Transaction History</h1>
          <p className="text-xl mb-8">Please connect your wallet to view your transaction history</p>
          <ConnectButton />
        </div>
      )}
    </>
  );
};

export default TransactionHistory;

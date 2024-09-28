"use client";

import { useState } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";
import { SwitchTheme } from "~~/components/SwitchTheme";

const Settings = () => {
  const { isConnected } = useAccount();
  const [notifications, setNotifications] = useState(true);
  const [language, setLanguage] = useState("English");
  const [currency, setCurrency] = useState("USD");

  return (
    <>
      {isConnected ? (
        <div className="bg-white/10 rounded-lg p-8 max-w-2xl mx-auto shadow-lg">
          <h2 className="text-3xl font-bold mb-8 text-center">Settings</h2>
          <div className="space-y-8">
            <div className="flex justify-between items-center bg-white/5 p-4 rounded-lg">
              <span className="text-lg font-medium">Theme</span>
              <SwitchTheme className="scale-125" />
            </div>
            <div className="flex justify-between items-center bg-white/5 p-4 rounded-lg">
              <span className="text-lg font-medium">Notifications</span>
              <input
                type="checkbox"
                className="toggle toggle-primary toggle-lg"
                checked={notifications}
                onChange={() => setNotifications(!notifications)}
              />
            </div>
            <div className="flex justify-between items-center bg-white/5 p-4 rounded-lg">
              <span className="text-lg font-medium">Language</span>
              <select
                className="select select-primary w-40 text-lg"
                value={language}
                onChange={e => setLanguage(e.target.value)}
              >
                <option>English</option>
                <option>Spanish</option>
                <option>French</option>
              </select>
            </div>
            <div className="flex justify-between items-center bg-white/5 p-4 rounded-lg">
              <span className="text-lg font-medium">Currency</span>
              <select
                className="select select-primary w-40 text-lg"
                value={currency}
                onChange={e => setCurrency(e.target.value)}
              >
                <option>USD</option>
                <option>EUR</option>
                <option>GBP</option>
              </select>
            </div>
          </div>
        </div>
      ) : (
        <div className="text-center py-20 bg-white/10 rounded-lg shadow-lg">
          <h1 className="text-4xl font-bold mb-6">Connect to Access Settings</h1>
          <p className="text-xl mb-10">Please connect your wallet to view and modify your settings</p>
          <ConnectButton />
        </div>
      )}
    </>
  );
};

export default Settings;

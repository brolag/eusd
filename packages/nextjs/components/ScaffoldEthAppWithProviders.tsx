"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { RainbowKitProvider, darkTheme, lightTheme } from "@rainbow-me/rainbowkit";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import { Toaster } from "react-hot-toast";
import { WagmiProvider } from "wagmi";
import { BlockieAvatar } from "~~/components/scaffold-eth";
import { ProgressBar } from "~~/components/scaffold-eth/ProgressBar";
import { useInitializeNativeCurrencyPrice } from "~~/hooks/scaffold-eth";
import { wagmiConfig } from "~~/services/web3/wagmiConfig";

const ScaffoldEthApp = ({ children }: { children: React.ReactNode }) => {
  useInitializeNativeCurrencyPrice();

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 to-purple-900 text-white">
      <header className="p-4 flex justify-between items-center">
        <div className="text-2xl font-bold">EUSD</div>
        <ConnectButton />
      </header>
      <nav className="container mx-auto px-4 py-4">
        <div className="grid grid-cols-2 md:grid-cols-6 gap-4">
          {["Dashboard", "Deposit", "Withdraw", "Claim EUSD", "Transaction History", "Settings"].map(item => (
            <Link
              key={item}
              href={item === "Dashboard" ? "/" : `/${item.toLowerCase().replace(" ", "-")}`}
              className="bg-white/10 hover:bg-white/20 transition-colors rounded-lg p-4 text-center"
            >
              {item}
            </Link>
          ))}
        </div>
      </nav>
      <main className="container mx-auto px-4 py-8">{children}</main>
      <Toaster />
    </div>
  );
};

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
    },
  },
});

export const ScaffoldEthAppWithProviders = ({ children }: { children: React.ReactNode }) => {
  const { resolvedTheme } = useTheme();
  const isDarkMode = resolvedTheme === "dark";
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <ProgressBar />
        <RainbowKitProvider
          avatar={BlockieAvatar}
          theme={mounted ? (isDarkMode ? darkTheme() : lightTheme()) : lightTheme()}
        >
          <ScaffoldEthApp>{children}</ScaffoldEthApp>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
};

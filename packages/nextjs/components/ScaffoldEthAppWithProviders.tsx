"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { RainbowKitProvider, darkTheme, lightTheme } from "@rainbow-me/rainbowkit";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import { Toaster } from "react-hot-toast";
import { WagmiProvider } from "wagmi";
import {
  ArrowDownTrayIcon,
  ArrowUpTrayIcon,
  ClockIcon,
  CogIcon,
  CurrencyDollarIcon,
  FireIcon,
  HomeIcon,
} from "@heroicons/react/24/outline";
import { BlockieAvatar } from "~~/components/scaffold-eth";
import { ProgressBar } from "~~/components/scaffold-eth/ProgressBar";
import { useInitializeNativeCurrencyPrice } from "~~/hooks/scaffold-eth";
import { wagmiConfig } from "~~/services/web3/wagmiConfig";

const ScaffoldEthApp = ({ children }: { children: React.ReactNode }) => {
  useInitializeNativeCurrencyPrice();

  const menuItems = [
    { name: "Dashboard", icon: HomeIcon, href: "/" },
    { name: "Deposit", icon: ArrowDownTrayIcon, href: "/deposit" },
    { name: "Claim EUSD", icon: CurrencyDollarIcon, href: "/claim-eusd" },
    { name: "Burn EUSD", icon: FireIcon, href: "/burn-eusd" },
    { name: "Withdraw", icon: ArrowUpTrayIcon, href: "/withdraw" },
    { name: "Transaction History", icon: ClockIcon, href: "/transaction-history" },
    { name: "Settings", icon: CogIcon, href: "/settings" },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 to-purple-900 text-white">
      <header className="p-4 flex justify-between items-center">
        <div className="text-2xl font-bold">EUSD</div>
        <ConnectButton />
      </header>
      <nav className="container mx-auto px-4 py-4">
        <div className="grid grid-cols-3 md:grid-cols-7 gap-2">
          {menuItems.map(({ name, icon: Icon, href }) => (
            <Link
              key={name}
              href={href}
              className="bg-white/10 hover:bg-white/20 transition-colors rounded-lg p-2 text-center flex flex-col items-center"
            >
              <Icon className="h-6 w-6 mb-1" />
              <span className="text-xs">{name}</span>
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

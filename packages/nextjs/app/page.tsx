"use client";

import { useEffect, useRef, useState } from "react";
import * as d3 from "d3";
import { useAccount, useBalance } from "wagmi";
import { BellIcon } from "@heroicons/react/24/outline";

const Home = () => {
  const { address: connectedAddress, isConnected } = useAccount();
  const { data: ethBalance } = useBalance({ address: connectedAddress });
  const [ethPrice, setEthPrice] = useState(0);
  const [eusdRate, setEusdRate] = useState(0);
  const [ethPriceHistory, setEthPriceHistory] = useState<number[]>([]);
  const [eusdRateHistory, setEusdRateHistory] = useState<number[]>([]);

  const ethChartRef = useRef<SVGSVGElement>(null);
  const eusdChartRef = useRef<SVGSVGElement>(null);

  useEffect(() => {
    setEthPrice(1800);
    setEusdRate(1800 * 0.8);
    setEthPriceHistory([1750, 1780, 1790, 1800, 1820, 1810, 1800]);
    setEusdRateHistory([1400, 1424, 1432, 1440, 1456, 1448, 1440]);
  }, []);

  useEffect(() => {
    if (ethPriceHistory.length > 0 && ethChartRef.current) {
      drawChart(ethChartRef.current, ethPriceHistory, "rgb(75, 192, 192)");
    }
    if (eusdRateHistory.length > 0 && eusdChartRef.current) {
      drawChart(eusdChartRef.current, eusdRateHistory, "rgb(255, 99, 132)");
    }
  }, [ethPriceHistory, eusdRateHistory]);

  const drawChart = (svgElement: SVGSVGElement, data: number[], color: string) => {
    const margin = { top: 20, right: 20, bottom: 30, left: 50 };
    const width = 600 - margin.left - margin.right;
    const height = 200 - margin.top - margin.bottom;

    const svg = d3
      .select(svgElement)
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", `translate(${margin.left},${margin.top})`);

    const x = d3
      .scaleLinear()
      .domain([0, data.length - 1])
      .range([0, width]);

    const y = d3
      .scaleLinear()
      .domain([d3.min(data) || 0, d3.max(data) || 0])
      .range([height, 0]);

    const line = d3
      .line<number>()
      .x((d, i) => x(i))
      .y(d => y(d));

    svg.append("path").datum(data).attr("fill", "none").attr("stroke", color).attr("stroke-width", 2).attr("d", line);

    svg.append("g").attr("transform", `translate(0,${height})`).call(d3.axisBottom(x));

    svg.append("g").call(d3.axisLeft(y));
  };

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

          <div className="bg-white/10 rounded-lg p-6 mb-6">
            <h2 className="text-xl font-semibold mb-4">Price Charts</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-white/5 p-4 rounded-md">
                <h3 className="text-lg font-semibold mb-2">ETH Price History</h3>
                <svg ref={ethChartRef} />
              </div>
              <div className="bg-white/5 p-4 rounded-md">
                <h3 className="text-lg font-semibold mb-2">EUSD Rate History</h3>
                <svg ref={eusdChartRef} />
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

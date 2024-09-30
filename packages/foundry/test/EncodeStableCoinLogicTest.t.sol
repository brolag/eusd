// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

// Import necessary contracts
import { DSTest } from "ds-test/test.sol"; // Foundry testing utility
import { TellorPlayground } from "../lib/usingtellor/contracts/TellorPlayground.sol"; // Import Tellor Playground
import { EncodeStableCoinLogic } from "../contracts/EncodeStableCoinLogic.sol"; // Logic contract
import { EncodeStableCoin } from "../contracts/EncodeStableCoin.sol"; // Stablecoin contract
import { Vm } from "forge-std/Vm.sol"; // Foundry cheat code

/**
 * @title EncodeStableCoinLogicTest
 * @notice This contract tests the Tellor Oracle integration for the EncodeStableCoinLogic contract.
 */
contract EncodeStableCoinLogicTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS); // Cheat code interface

    EncodeStableCoinLogic stableCoinLogic;
    EncodeStableCoin stableCoin;
    TellorPlayground tellorPlayground;

    function setUp() public {
        // Deploy the Tellor Playground contract (mock Tellor oracle)
        tellorPlayground = new TellorPlayground();

        // Deploy EncodeStableCoin contract
        stableCoin = new EncodeStableCoin(address(this));

        // Deploy EncodeStableCoinLogic with Tellor Playground address
        stableCoinLogic = new EncodeStableCoinLogic(address(stableCoin), payable(address(tellorPlayground)));
    }

    /**
    * @notice Test that the getETHUSDPrice function returns the correct price from Tellor Oracle.
    */
    function testGetETHUSDPrice() public {
    // Step 1: Define the queryId for the ETH/USD price request
    bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth", "usd")));
    
    // Step 2: Set a mock ETH price (e.g., 3000 USD per ETH)
    uint256 mockETHPrice = 3000 * 1e18;  // Mock price in wei

    // Step 3: Submit the mock ETH price to the Tellor Playground
    tellorPlayground.submitValue(queryId, abi.encode(mockETHPrice), 0, abi.encode("eth", "usd"));

    // Step 4: Call the getETHUSDPrice function from EncodeStableCoinLogic
    uint256 fetchedPrice = stableCoinLogic.getETHUSDPrice();

    // Step 5: Assert that the fetched price matches the mock price
    assertEq(fetchedPrice, mockETHPrice, "The fetched ETH price should match the mock price");
    }

    /**
    * @notice Test that getETHUSDPrice reverts if the data from Tellor is stale.
    */
    function testStaleETHUSDPrice() public {
    // Step 1: Define the queryId for the ETH/USD price request
    bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth", "usd")));

    // Step 2: Set a mock ETH price (e.g., 3000 USD per ETH)
    uint256 mockETHPrice = 3000 * 1e18;

    // Step 3: Submit the mock ETH price with the current timestamp
    tellorPlayground.submitValue(queryId, abi.encode(mockETHPrice), 0, abi.encode("eth", "usd"));

    // Step 4: Manipulate time to simulate stale data (warp time by 2 days)
    vm.warp(block.timestamp + 2 days);

    // Step 5: Expect the contract to revert due to stale data
    vm.expectRevert("Data is stale");
    stableCoinLogic.getETHUSDPrice();
    }

    /**
    * @notice Test that getETHUSDPrice reverts when no data is available from Tellor Oracle.
    */
    function testNoDataAvailable() public {
    // Step 1: Define the queryId for the ETH/USD price request
    bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode("eth", "usd")));

    // Step 2: Ensure that no data is available in Tellor Playground

    // Step 3: Expect the contract to revert due to no data available
    vm.expectRevert("No data available");
    stableCoinLogic.getETHUSDPrice();
    }
}

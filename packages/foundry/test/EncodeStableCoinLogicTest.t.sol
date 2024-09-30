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
}

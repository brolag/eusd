// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title eUSD
 * @author Aziz RaY
 * Collateral: Exogenous (ETH)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 * 
 * This is the contract meant to be governed by eUSDEngie. This contract is the ERC20 implementation of our stablecoin system.
 * 
 */

contract eUSD is ERC20Burnable, Ownable {
    error eUSD_MustBeMoreThanZero();
    error eUSD_BurnAmountExceedsBalance();


    constructor()ERC20("eUSD", "eUSD") {
        // constructor
    }
    function burn(uint256 _amount) public override onlyOwner {
    uint256 balance = balanceOf(msg.sender);
    if (_amount <= 0) {
        revert eUSD_MustBeMoreThanZero();
    }
    if (balance < _amount) {
        revert eUSD_BurnAmountExceedsBalance();

    }
    super.burn(_amount);
}

}

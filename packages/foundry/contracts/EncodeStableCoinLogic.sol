// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

//Import the stablecoin contract
import { EncodeStableCoin } from "./EncodeStableCoin.sol";

/**
 * @title EncodeStableCoinLogic
 * @notice This contract handles the minting, burning, collateral management, and liquidation logic for the EncodeStableCoin (EUSD).
 */
contract EncodeStableCoinLogic {
    error AmountMustBeMoreThanZero();
    error ZeroAddress();
    error InsufficientMintedBalance(); // New error for burning more than minted 

    // State Variables
    EncodeStableCoin private immutable stableCoin; // Reference to the EncodeStableCoin contract
    mapping(address => uint256) private stableCoinMinted; // Tracks the amount of EUSD minted per user

    /**
     * @dev Constructor to initialize the EncodeStableCoin contract.
     * @param _stableCoin The address of the EncodeStableCoin contract.
     */
    constructor(address _stableCoin) {
    stableCoin = EncodeStableCoin(_stableCoin); // Initialize stablecoin reference
    }

    /**
     * @notice Mint EUSD tokens for a user.
     * @param _to The address that will receive the minted EUSD.
     * @param _amount The amount of EUSD to mint.
     */
    function mintEUSD(address _to, uint256 _amount) external {
        require (_to != address(0), ZeroAddress()); // Ensure the address is not the zero address
        require (_amount > 0, AmountMustBeMoreThanZero()); // Ensure the amount is greater than zero

        stableCoinMinted[_to] += _amount; //Track minted amount
        stableCoin.mint(_to, _amount); // Call mint function on the stablecoin contract 
    }

    /**
     * @notice Burn EUSD tokens from the caller.
     * @param _amount The amount of EUSD to burn.
     */
    function burnEUSD(uint256 _amount) external {
        require (_amount > 0, AmountMustBeMoreThanZero()); // Ensure the amount is greater than zero

        // Check if the user has enough minted balance to burn
        if (stableCoinMinted[msg.sender] <_amount) {
            revert InsufficientMintedBalance(); // Revert if trying to burn more than minted
        }


    stableCoinMinted[msg.sender] -= _amount; // Update the amount of minted stablecoin for the caller
    stableCoin.burn(_amount); // Call burn function on the stablecoin contract
        
    }

    
    function addCollateral() external  {
    }

    function redeemCollateral() external {
    }

    function liquidate() external {
    }

    function liquidationStatus() public view returns (bool status) {
    }

    function getETHUSDPrice() public view returns (uint256 price) {
    }

    function _convertToETH(uint256 _amount) internal returns (uint256 ethAmount) {
    }

    function _convertToUSD(uint256 _amount) internal returns (uint256 usdAmount) {
    }
}
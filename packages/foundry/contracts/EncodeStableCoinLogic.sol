// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

//Import the stablecoin contract
import { EncodeStableCoin } from "./EncodeStableCoin.sol";
//Import the Tellor contract
import { UsingTellor } from "usingtellor/contracts/UsingTellor.sol";

/**
 * @title EncodeStableCoinLogic
 * @notice This contract handles the minting, burning, collateral management, and liquidation logic for the EncodeStableCoin (EUSD).
 */
contract EncodeStableCoinLogic {
    mapping(address => uint256) public collateralAmount;

    error AmountMustBeMoreThanZero();
    error ZeroAddress();
    error InsufficientMintedBalance(); // New error for burning more than minted 

    // State Variables
    EncodeStableCoin private immutable stableCoin; // Reference to the EncodeStableCoin contract
    mapping(address => uint256) private stableCoinMinted; // Tracks the amount of EUSD minted per user

    /**
     * @dev Constructor to initialize the EncodeStableCoin contract and Tellor oracle.
     * @param _stableCoin The address of the EncodeStableCoin contract.
     * @param _tellorAddress The address of the Tellor oracle contract.
     * 
     * This constructor initializes the EncodeStableCoinLogic contract by setting the EncodeStableCoin reference
     * and passing the Tellor oracle address to the inherited UsingTellor contract. The Tellor oracle is used to fetch
     * external price data, specifically the ETH/USD price.
     */
    constructor(address _stableCoin, address payable _tellorAddress) UsingTellor(_tellorAddress) {
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

    
    /**
     * @dev This function is used to deposit collateral to the vault.
     * msg.value is the amount of collateral to deposit
     * msg.sender is the user who is depositing the collateral
     */
    function addCollateral() external payable {
        collateralAmount[msg.sender] += msg.value;
    }

    function redeemCollateral() external {
    }

    /**
     * @dev This function is used to check the collateral amount for a user.
     * @param _user The address of the user to check the collateral amount for.
     * @return The collateral amount for the user.
     */
    function checkCollateralOf(address _user) external view returns (uint256) {
        return collateralAmount[_user];
    }

    function liquidate() external {
    }

    function liquidationStatus() public view returns (bool status) {
    }

/**
     * @notice Fetch ETH/USD price using Tellor Oracle
     * @return price The ETH/USD price
     */
    function getETHUSDPrice() public view returns (uint256 price) {
        bytes memory _queryData = abi.encode("SpotPrice", abi.encode("eth", "usd"));
        bytes32 _queryId = keccak256(_queryData);
        (bytes memory _value, uint256 _timestamp) = _getDataBefore(_queryId, block.timestamp - 1 hours);

        require(_timestamp > 0, "No data available");
        require(block.timestamp - _timestamp < 1 days, "Data is stale");

        price = abi.decode(_value, (uint256));
        return price;
    }

    function _convertToETH(uint256 _amount) internal returns (uint256 ethAmount) {
    }

    function _convertToUSD(uint256 _amount) internal returns (uint256 usdAmount) {
    }
}
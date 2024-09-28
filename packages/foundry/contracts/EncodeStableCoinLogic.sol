// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

contract EncodeStableCoinLogic {
    error AmountMustBeMoreThanZero();
    error ZeroAddress();


    constructor() {}
    
    function mintEUSD(address _to, uint256 _amount) external {
        require (_to != address(0), ZeroAddress());
        require (_amount > 0, AmountMustBeMoreThanZero()); 
    }
    function burnEUSD(uint256 _amount) external {
        require (_amount > 0, AmountMustBeMoreThanZero()); 
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
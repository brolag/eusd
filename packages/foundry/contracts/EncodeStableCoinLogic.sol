// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

contract EncodeStableCoinLogic {
    mapping(address => uint256) public collateralAmount;

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

    function getETHUSDPrice() public view returns (uint256 price) {
    }

    function _convertToETH(uint256 _amount) internal returns (uint256 ethAmount) {
    }

    function _convertToUSD(uint256 _amount) internal returns (uint256 usdAmount) {
    }
}
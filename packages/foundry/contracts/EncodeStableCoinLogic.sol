// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {EncodeStableCoin} from "./EncodeStableCoin.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title EncodeStableCoinLogic
 * @notice This contract handles the minting, burning, collateral management, and liquidation logic for the EncodeStableCoin (EUSD).
 */
contract EncodeStableCoinLogic is Ownable, ReentrancyGuard {
    //////////////// Errors \\\\\\\\\\\\\\\\

    error AmountMustBeMoreThanZero();
    error ZeroAddress();
    error HealthFactorIsNotOk(address user);
    error LiquidationStatusIsOk();
    error AmountToCoverIsMoreThanTheDebt();

    //////////////// Types \\\\\\\\\\\\\\\\

    using SafeERC20 for IERC20;

    //////////////// State Variables \\\\\\\\\\\\\\\\

    uint256 private constant COLLATERALIZATION_RATIO = 2 * 1e16; // 100% overcollateralization needed to mint EUSD
    uint256 private constant LIQUIDATION_THRESHOLD = 1.75 * 1e16; // If overcollateralization is less then 75% liquidation is triggered
    uint256 private constant LIQUIDATION_BONUS = 0.1 * 1e18; // 10% liquidation penalty
    uint256 private constant MIN_HEALTH_FACTOR = 100; // 1 health factor
    uint256 private constant PRECISION = 1e18; // Precision for calculations
    uint256 private constant PRECISION_FOR_DEBT_CALCULATIONS = 1e16; // Precision for debt calculations
    uint256 private constant FEE = 0.003 * 1e18; // 0,3% fee

    EncodeStableCoin private immutable i_eUSD; // Reference to the EncodeStableCoin contract
    IERC20 private immutable i_collateralToken; // Reference to the collateral token
    address private immutable i_priceFeedAddress; // Reference to the price feed contract

    uint256 private collectedFees; // Tracks the amount of fees collected
    uint256 private totalUsersCollateral; // Tracks the total amount of collateral deposited
    uint256 private totalEUSDMinted; // Tracks the total amount of EUSD minted
    mapping(address => uint256) private eUSDMinted; // Tracks the amount of EUSD minted per user
    mapping(address => uint256) private collateralDeposited; // Tracks the amount of collateral deposited per user

    //////////////// Events \\\\\\\\\\\\\\\\

    event EUSDMinted(address indexed user, uint256 indexed amount);
    event EUSDBurned(address indexed user, uint256 indexed amount);
    event CollateralDeposited(address indexed user, uint256 indexed amount);
    event CollateralRedeemed(address indexed user, uint256 indexed amount);
    event UserLiquidated(address indexed user, uint256 indexed amount);
    event FeesWithdrawn(address indexed to, uint256 feesToWithdrawn);
    event ExtraCollateralWithdrawn(
        address indexed to,
        uint256 indexed amountWithdrawn,
        uint256 indexed remainingCollateral
    );

    //////////////// Modifiers \\\\\\\\\\\\\\\\

    modifier mustBeMoreThanZero(uint256 amount) {
        require(amount > 0, AmountMustBeMoreThanZero());
        _;
    }

    modifier notZeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }
    //////////////// Functions \\\\\\\\\\\\\\\\

    /**
     * @dev Constructor to initialize the EncodeStableCoin contract.
     * @param eUSDAddress The address of the EncodeStableCoin contract.
     * @param collateralTokenAddress The address of the collateral token.
     * @param priceFeedAddress The address of the price feed contract.
     */
    constructor(
        address eUSDAddress,
        address collateralTokenAddress,
        address priceFeedAddress
    )
        Ownable(msg.sender)
        notZeroAddress(eUSDAddress)
        notZeroAddress(collateralTokenAddress)
        notZeroAddress(priceFeedAddress)
    {
        i_eUSD = EncodeStableCoin(eUSDAddress);
        i_collateralToken = IERC20(collateralTokenAddress);
        i_priceFeedAddress = priceFeedAddress;
    }

    //////////////// External Functions \\\\\\\\\\\\\\\\

    /**
     * @notice Mint EUSD tokens for a user.
     * @dev Mints the specified amount of EUSD after deducting the minting fee and checking the user's health factor.
     * @param amount The amount of EUSD to mint.
     * Emits a {EUSDMinted} event.
     * Reverts with `HealthFactorIsNotOk` if the health factor of the user is not sufficient.
     */
    function mintEUSD(
        uint256 amount
    ) external nonReentrant mustBeMoreThanZero(amount) {
        uint256 fee = (amount * FEE) / PRECISION;
        fee = _convertToCollateralToken(fee);
        collectedFees += fee;
        collateralDeposited[msg.sender] -= fee;
        totalUsersCollateral -= fee;
        i_eUSD.mint(msg.sender, amount);
        totalEUSDMinted += amount;
        require(
            _checkHealthFactor(msg.sender),
            HealthFactorIsNotOk(msg.sender)
        );
        emit EUSDMinted(msg.sender, amount);
    }

    /**
     * @notice Burn EUSD tokens from the caller.
     * @dev Burns the specified amount of EUSD and updates the user’s health factor.
     * @param amount The amount of EUSD to burn.
     * Emits a {eUSDBurned} event.
     */
    function burnEUSD(
        uint256 amount
    ) external nonReentrant mustBeMoreThanZero(amount) {
        eUSDMinted[msg.sender] -= amount;
        i_eUSD.burn(msg.sender, amount);
        totalEUSDMinted -= amount;
        emit EUSDBurned(msg.sender, amount);
    }

    /**
     * @notice Add collateral to the user's account.
     * @dev Transfers collateral tokens from the user to the contract.
     * @param amount The amount of collateral to deposit.
     * Emits a {CollateralDeposited} event.
     */
    function addCollateral(
        uint256 amount
    ) external nonReentrant mustBeMoreThanZero(amount) {
        collateralDeposited[msg.sender] += amount;
        totalUsersCollateral += amount;
        i_collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        emit CollateralDeposited(msg.sender, amount);
    }

    /**
     * @notice Redeem collateral from the contract.
     * @dev Allows the user to redeem their collateral based on the amount specified.
     * The function checks the health factor if the user has an outstanding EUSD balance.
     * @param amount The amount of collateral to redeem.
     * Emits a {CollateralRedeemed} event.
     * Reverts with `HealthFactorIsNotOk` if the health factor is not sufficient after redemption.
     */
    function redeemCollateral(
        uint256 amount
    ) external nonReentrant mustBeMoreThanZero(amount) {
        collateralDeposited[msg.sender] -= amount;
        totalUsersCollateral -= amount;
        i_collateralToken.safeTransfer(msg.sender, amount);
        if (eUSDMinted[msg.sender] != 0) {
            require(
                _checkHealthFactor(msg.sender),
                HealthFactorIsNotOk(msg.sender)
            );
        }
        emit CollateralRedeemed(msg.sender, amount);
    }

    /**
     * @notice Liquidate a user whose health factor is below the liquidation threshold.
     * @dev Covers the debt of the user up to the specified amount and transfers the collateral with a bonus to the liquidator.
     * @param user The user to be liquidated.
     * @param amountToCover The amount of EUSD to cover in liquidation.
     * Emits {userLiquidated} and {CollateralRedeemed} events.
     * Reverts with `LiquidationStatusIsOk` if the user is not in a liquidation state.
     * Reverts with `AmountToCoverIsMoreThanTheDebt` if the amount to cover exceeds the user's debt.
     * Reverts with `HealthFactorIsNotOk` if the health factor of liquidator is not sufficient after liquidation.
     */
    function liquidateUser(
        address user,
        uint256 amountToCover
    ) external mustBeMoreThanZero(amountToCover) nonReentrant {
        require(
            liquidationStatus(user) >= MIN_HEALTH_FACTOR,
            LiquidationStatusIsOk()
        );
        uint256 amountToCoverAllDebt = getEUSDAmountToImproveLiquidationStatus(
            user
        );
        require(
            amountToCover <= amountToCoverAllDebt,
            AmountToCoverIsMoreThanTheDebt()
        );
        uint256 debtInCollateral = _convertToCollateralToken(amountToCover);
        uint256 amountWithBonus = debtInCollateral +
            ((debtInCollateral * LIQUIDATION_BONUS) / PRECISION);
        eUSDMinted[msg.sender] -= amountToCover;
        eUSDMinted[user] -= amountToCover;
        i_eUSD.burn(msg.sender, amountToCover);
        emit EUSDBurned(msg.sender, amountToCover);
        collateralDeposited[user] -= amountWithBonus;
        emit CollateralRedeemed(user, amountWithBonus);
        i_collateralToken.safeTransfer(msg.sender, amountWithBonus);
        require(
            _checkHealthFactor(msg.sender),
            HealthFactorIsNotOk(msg.sender)
        );
        emit CollateralDeposited(msg.sender, amountWithBonus);
        emit UserLiquidated(user, amountToCover);
    }
    /**
     * @notice Withdraw collected fees to a specified address.
     * @dev Only the owner can call this function.
     * @param to The address to send the fees to.
     * Emits a {FeesWithdrawn} event.
     */
    function withdrawFees(
        address to
    ) external onlyOwner nonReentrant notZeroAddress(to) {
        uint256 feesToWithdraw = collectedFees;
        collectedFees = 0;
        i_collateralToken.safeTransfer(to, feesToWithdraw);
        emit FeesWithdrawn(to, feesToWithdraw);
    }

    /**
     * @notice Withdraw extra collateral to a specified address.
     * @dev Only the owner can call this function.
     * @param to The address to send the extra collateral to.
     * Emits an {ExtraCollateralWithdrawn} event.
     */
    function withdrawExtraCollateral(
        address to
    ) external onlyOwner nonReentrant notZeroAddress(to) {
        uint256 extraCollateral = i_collateralToken.balanceOf(address(this)) -
            totalUsersCollateral;
        uint256 remainingCollateral = i_collateralToken.balanceOf(
            address(this)
        ) - extraCollateral;
        i_collateralToken.safeTransfer(to, extraCollateral);
        emit ExtraCollateralWithdrawn(to, extraCollateral, remainingCollateral);
    }

    //////////////// Internal View Functions \\\\\\\\\\\\\\\\

    function _checkHealthFactor(
        address user
    ) internal view returns (bool healthFactor) {
        healthFactor = healthFactorOfUser(user) >= MIN_HEALTH_FACTOR;
    }

    function _convertToCollateralToken(
        uint256 amount
    ) internal view returns (uint256 ethAmount) {
        uint256 ethPrice = getCollateralUSDPrice();
        ethAmount = amount / ethPrice;
    }

    function _convertToUSD(
        uint256 amount
    ) internal view returns (uint256 usdAmount) {
        uint256 ethPrice = getCollateralUSDPrice();
        usdAmount = amount * ethPrice;
    }

    //////////////// Public and External View Functions \\\\\\\\\\\\\\\\

    function liquidationStatus(
        address user
    ) public view returns (uint256 healthFactor) {
        uint256 collateralInUSD = _convertToUSD(collateralDeposited[user]);
        uint256 eUSDUserBalance = eUSDMinted[user];
        healthFactor =
            (collateralInUSD * PRECISION) /
            (eUSDUserBalance * LIQUIDATION_THRESHOLD);
    }

    function healthFactorOfUser(
        address user
    ) public view returns (uint256 healthFactor) {
        uint256 collateralUserBalanceInUsd = _convertToUSD(
            collateralDeposited[user]
        );
        uint256 eUSDUserBalance = eUSDMinted[user];
        healthFactor =
            (collateralUserBalanceInUsd * PRECISION) /
            (eUSDUserBalance * COLLATERALIZATION_RATIO);
    }

    function getCollateralUSDPrice() public view returns (uint256 price) {
        // here must be fetched information from Teller
    }

    function getEUSDAmountToImproveLiquidationStatus(
        address user
    ) public view returns (uint256 difference) {
        uint256 collateralInUSD = _convertToUSD(collateralDeposited[user]);
        uint256 eUSDUserBalance = eUSDMinted[user];
        uint256 eUSDUserBalanceMustHave = (collateralInUSD *
            PRECISION_FOR_DEBT_CALCULATIONS) / LIQUIDATION_THRESHOLD;
        difference = eUSDUserBalanceMustHave - eUSDUserBalance;
    }

    function getCollaterizationRatio() external pure returns (uint256) {
        return COLLATERALIZATION_RATIO;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getFee() external pure returns (uint256) {
        return FEE;
    }

    function getEUSDAddress() external view returns (address) {
        return address(i_eUSD);
    }

    function getCollateralTokenAddress() external view returns (address) {
        return address(i_collateralToken);
    }

    function getPriceFeedAddress() external view returns (address) {
        return i_priceFeedAddress;
    }

    function getTotalUsersCollateral() external view returns (uint256) {
        return totalUsersCollateral;
    }

    function getTotalEUSDMinted() external view returns (uint256) {
        return totalEUSDMinted;
    }

    function getEUSDTotalCollateralization() external view returns (uint256) {
        // used precisions to return the value in percentage
        return
            (_convertToUSD(totalUsersCollateral) * PRECISION) /
            (totalEUSDMinted * PRECISION_FOR_DEBT_CALCULATIONS);
    }
}

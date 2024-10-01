// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

//Import the stablecoin contract
import {EncodeStableCoin} from "./EncodeStableCoin.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title EncodeStableCoinLogic
 * @notice This contract handles the minting, burning, collateral management, and liquidation logic for the EncodeStableCoin (EUSD).
 */
contract EncodeStableCoinLogic is Ownable, ReentrancyGuard {
    // Errors
    error AmountMustBeMoreThanZero();
    error ZeroAddress();
    error HealthFactorIsNotOk(address user);
    error liquidationStatusIsOk();

    // Types
    using SafeERC20 for IERC20;

    // State Variables
    uint256 private constant COLLATERALIZATION_RATIO = 2 * 1e18; // 100% overcollateralization needed to mint EUSD
    uint256 private constant LIQUIDATION_THRESHOLD = 1.75 * 1e18; // If overcollateralization is less then 75% liquidation is triggered
    uint256 private constant LIQUIDATION_BONUS = 0.1 * 1e18; // 10% liquidation penalty
    uint256 private constant MIN_HEALTH_FACTOR = 1 * 1e18; // 1 health factor
    uint256 private constant PRECISION = 1e18; // Precision for calculations
    uint256 private constant FEE = 0.003 * 1e18; // 0,3% fee

    EncodeStableCoin private immutable i_stableCoin; // Reference to the EncodeStableCoin contract
    IERC20 private immutable i_collateralToken; // Reference to the collateral token
    address private immutable i_priceFeedAddress; // Reference to the price feed contract
    uint256 private collectedFees; // Tracks the amount of fees collected
    uint256 private totalUsersCollateral; // Tracks the total amount of collateral deposited
    uint256 private totalEUSD; // Tracks the total amount of EUSD minted
    mapping(address => uint256) private stableCoinMinted; // Tracks the amount of EUSD minted per user
    mapping(address => uint256) private collateralDeposited; // Tracks the amount of collateral deposited per user

    //Events
    event eUSDMinted(address indexed user, uint256 indexed amount);
    event eUSDBurned(address indexed user, uint256 indexed amount);
    event CollateralDeposited(address indexed user, uint256 indexed amount);
    event CollateralRedeemed(address indexed user, uint256 indexed amount);
    event userLiquidated(address indexed user, uint256 indexed amount);

    //modifiers
    modifier mustBeMoreThanZero(uint256 amount) {
        require(amount > 0, "Amount must be more than zero");
        _;
    }
    /**
     * @dev Constructor to initialize the EncodeStableCoin contract.
     * @param stableCoinAddress The address of the EncodeStableCoin contract.
     * @param collateralTokenAddress The address of the collateral token.
     */

    constructor(address stableCoinAddress, address collateralTokenAddress, address priceFeedAddress)
        Ownable(msg.sender)
    {
        i_stableCoin = EncodeStableCoin(stableCoinAddress);
        i_collateralToken = IERC20(collateralTokenAddress);
        i_priceFeedAddress = priceFeedAddress;
    }

    /**
     * @notice Mint EUSD tokens for a user.
     * @param amount The amount of EUSD to mint.
     */
    function mintEUSD(uint256 amount) external nonReentrant mustBeMoreThanZero(amount) {
        uint256 fee = (amount * FEE) / PRECISION;
        fee = _convertToETH(fee);
        collectedFees += fee;
        collateralDeposited[msg.sender] -= fee;
        totalUsersCollateral -= fee;
        i_stableCoin.mint(msg.sender, amount);
        totalEUSD += amount;
        require(_checkHealthFactor(msg.sender), HealthFactorIsNotOk(msg.sender));
        emit eUSDMinted(msg.sender, amount);
    }

    /**
     * @notice Burn EUSD tokens from the caller.
     * @param amount The amount of EUSD to burn.
     */
    function burnEUSD(uint256 amount) external nonReentrant mustBeMoreThanZero(amount) {
        stableCoinMinted[msg.sender] -= amount;
        i_stableCoin.burn(msg.sender, amount);
        totalEUSD -= amount;
        require(_checkHealthFactor(msg.sender), HealthFactorIsNotOk(msg.sender));
        emit eUSDBurned(msg.sender, amount);
    }

    function addCollateral(uint256 amount) external mustBeMoreThanZero(amount) {
        collateralDeposited[msg.sender] += amount;
        totalUsersCollateral += amount;
        i_collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        emit CollateralDeposited(msg.sender, amount);
    }

    function redeemCollateral(uint256 amount) external mustBeMoreThanZero(amount) {
        collateralDeposited[msg.sender] -= amount;
        totalUsersCollateral -= amount;
        i_collateralToken.safeTransfer(msg.sender, amount);
        if (stableCoinMinted[msg.sender] != 0) {
            require(_checkHealthFactor(msg.sender), HealthFactorIsNotOk(msg.sender));
        }
        emit CollateralRedeemed(msg.sender, amount);
    }

    function liquidateUser(address user, uint256 amountToCover)
        external
        mustBeMoreThanZero(amountToCover)
        nonReentrant
    {
        require(!liquidationStatus(user), liquidationStatusIsOk());
        uint256 debtInCollateral = _convertToETH(amountToCover);
        uint256 amountWithBonus = debtInCollateral + ((debtInCollateral * LIQUIDATION_BONUS) / PRECISION);
        i_stableCoin.transferFrom(msg.sender, address(this), amountToCover);
        stableCoinMinted[msg.sender] -= amountToCover;
        stableCoinMinted[user] -= amountToCover;
        i_stableCoin.burn(address(this), amountToCover);
        emit eUSDBurned(msg.sender, amountToCover);
        collateralDeposited[user] -= amountWithBonus;
        emit CollateralRedeemed(user, amountWithBonus);
        i_collateralToken.safeTransfer(msg.sender, amountWithBonus);
        require(_checkHealthFactor(msg.sender), HealthFactorIsNotOk(msg.sender));
        emit CollateralDeposited(msg.sender, amountWithBonus);
        emit userLiquidated(user, amountToCover);
    }

    function withdrawFees(address to) external onlyOwner {
        i_collateralToken.safeTransfer(to, collectedFees);
        collectedFees = 0;
    }

    function liquidationStatus(address user) public view returns (bool status) {
        uint256 collateralInUSD = _convertToUSD(collateralDeposited[user]);
        uint256 eUSDUserBalance = stableCoinMinted[user];
        uint256 healthFactor = (collateralInUSD) / (eUSDUserBalance * LIQUIDATION_THRESHOLD);
        status = healthFactor >= MIN_HEALTH_FACTOR;
    }

    function healthFactorOfUser(address user) public view returns (uint256 healthFactor) {
        uint256 collateralUserBalanceInUsd = _convertToUSD(collateralDeposited[user]);
        uint256 eUSDUserBalance = stableCoinMinted[user];
        healthFactor = (collateralUserBalanceInUsd) / (eUSDUserBalance * COLLATERALIZATION_RATIO);
    }

    function getETHUSDPrice() public view returns (uint256 price) {
        // here must be fetched information from Teller
    }

    function _checkHealthFactor(address user) internal view returns (bool healthFactor) {
        healthFactor = healthFactorOfUser(user) >= MIN_HEALTH_FACTOR;
    }

    function _convertToETH(uint256 _amount) internal view returns (uint256 ethAmount) {
        uint256 ethPrice = getETHUSDPrice();
        ethAmount = _amount / ethPrice;
    }

    function _convertToUSD(uint256 _amount) internal view returns (uint256 usdAmount) {
        uint256 ethPrice = getETHUSDPrice();
        usdAmount = _amount * ethPrice;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/EncodeStableCoinLogic.sol";

contract EncodeStableCoinLogicTest is Test {
  EncodeStableCoinLogic public encodeStableCoinLogic;

  function setUp() public {
    encodeStableCoinLogic = new EncodeStableCoinLogic();
  }

  function testDepositCollateral() public {
    address account = address(0x1234);
    vm.deal(account, 1 ether);

    vm.prank(account);
    encodeStableCoinLogic.addCollateral{value: 1 ether}();

    assertEq(encodeStableCoinLogic.checkCollateralOf(account), 1 ether);
  }
}

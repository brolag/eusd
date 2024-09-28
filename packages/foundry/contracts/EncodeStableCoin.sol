// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EncodeStableCoin is ERC20Burnable, Ownable {

    constructor(address engine) ERC20("EncodeStableCoin", "EUSD") Ownable(engine) {}

    function burn(uint256 _amount) public override onlyOwner {
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EncodeStableCoin is ERC20, Ownable {
    constructor() ERC20("EncodeStableCoin", "EUSD") Ownable(msg.sender) {}
    //after deploying the contracts, the ownership must be transferred to the Logic contract

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DONUTToken is ERC20, Ownable {
    constructor() ERC20("DONUT token", "DONUT") {
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DOTToken is ERC20{
    constructor() ERC20("DOT Token", "DOT") {
        _mint(msg.sender, 52000000 * 10 ** decimals());
    }

}
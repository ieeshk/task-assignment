// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintToken is IERC20 {
    function mint(address _receiver, uint256 _amount) external returns (bool);
}
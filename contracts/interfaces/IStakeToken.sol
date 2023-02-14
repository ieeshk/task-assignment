// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakeToken is IERC20{
    // struct balanceStatus {
    //     uint256 totalTokens;
    //     uint256 lockedTokens;
    //     uint256 unlockedTokens;
    // }
    function mint() external;

    //function userBalanceStatus(address _user) external returns(balanceStatus memory _balanceStatus);
}
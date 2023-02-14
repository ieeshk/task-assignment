// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStakeToken.sol";
import "hardhat/console.sol";


contract lockedTokens {
    // struct balanceStatus {
    //     uint256 totalTokens;
    //     uint256 lockedTokens;
    //     uint256 unlockedTokens;
    // }

    //mapping(address => balanceStatus) public userBalanceStatus;

    IStakeToken public immutable stakingToken;

    address public owner;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(address _stakingToken) {
        owner = msg.sender;
        stakingToken = IStakeToken(_stakingToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }


    

    // function lockTokens(uint256 _amount) external {
    //    userBalanceStatus[msg.sender].lockedTokens += _amount;
    // }

    
    function stake(uint _amount) external {
        require(_amount > 0, "amount = 0");
        
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        // userBalanceStatus[msg.sender].lockedTokens += _amount;
        // userBalanceStatus[msg.sender].totalTokens += _amount;
        totalSupply += _amount;
    }
    
    function withdraw(uint _amount) external {
        require(_amount > 0, "amount = 0");
        require(balanceOf[msg.sender] >= _amount, "Not enough tokens to withdraw");
        //require(userBalanceStatus[msg.sender].lockedToken >= _amount, "not enough Locked tokens");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        //userBalanceStatus[msg.sender].lockedTokens -= _amount;
        //userBalanceStatus[msg.sender].unlockedTokens += _amount;
    }

}

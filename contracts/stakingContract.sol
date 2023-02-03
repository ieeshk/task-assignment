// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IMintToken.sol";
import "hardhat/console.sol";


contract StakingRewards{
    using SafeERC20 for IMintToken;
    
    struct StakedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => StakedBalance[]) public stakeDetails;
    
    IERC20 public immutable stakingToken;
    IMintToken public immutable rewardsToken;

    address public owner;

    uint256 public constant rewardDuration = 86400;
    uint256 public constant lockDuration = rewardDuration * 28;

    mapping(address => bool) public mintAllowed;

    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    
    // Reward to be paid out per second
    //345600 tokens to be paid out in 86400 seconds 
    uint public constant rewardRate = 4 * 1e18;
    
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    
    //bool firstTime = true;
    
    mapping(address => bool) public isWithdrawn;

    mapping(address => uint256) private _lastWithdrawalTime;
    uint256 public constant coolDownPeriod = 5 minutes;

    uint256 public lastWithdrawTime;

    // Total supply
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(
        address indexed user,
        address indexed rewardsToken,
        uint256 reward
    );
    event RewardAdded(uint256 rewardAmount);


    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        mintAllowed[msg.sender] = true;
        mintAllowed[(address(this))] = true;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IMintToken(_rewardToken);

    }


    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = block.timestamp;
        if (_account != address(0)) {         
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account]= rewardPerTokenStored;
            
        }

        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }
    // modifier coolTime(address _account) {
    //     if(firstTime){
    //         firstTime = false;
    //         _lastWithdrawalTime[_account] = block.timestamp;
    //     }
    //     require(block.timestamp >= (_lastWithdrawalTime[_account] + 5 minutes), "Cooldown time not completed");

    //     _;
    // }

    // modifier addReward() {
    //         uint256 timeGap = block.timestamp - lastWithdrawTime;
    //         uint256 totalRewardsAdded = rewardRate * 1e18 * timeGap;
    //         rewardsToken.mint(address(this), totalRewardsAdded);
    //         emit RewardAdded(totalRewardsAdded);            
    //     _;
    // }

    
    function coolDownPeriodStatus(address _account) public returns(bool) {
        uint256 currentTime;
        if(isWithdrawn[_account] == false){
        currentTime = block.timestamp;
        _lastWithdrawalTime[_account] = currentTime + coolDownPeriod;
        isWithdrawn[_account] = true;
        }
        //_lastWithdrawalTime[_account] = currentTime + coolDownPeriod;
        if(block.timestamp > _lastWithdrawalTime[_account]){
            return true;
        }
        else {
            return false;
        }

        // uint256 currentTime;      
        // //address to timeStamp
        // //current timestamp - last timestamp > cooldownPeriod && isWithdrawn
        // if(_lastWithdrawalTime[_account] == 0){
        //     currentTime = block.timestamp;
        // }
        //  _lastWithdrawalTime[_account] = block.timestamp;
        //  isWithdrawn[_account] = true;
        // if(block.timestamp - ) 

        // //_lastWithdrawalTime[_account] = _time;
        // return (block.timestamp > (currentTime + 5 minutes));
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (rewardRate * (block.timestamp - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        StakedBalance[] storage bal = stakeDetails[msg.sender];
        uint256 unlockTime = block.timestamp + lockDuration;
        uint index = stakeDetails[msg.sender].length;
        if(index == 0 || bal[index-1].unlockTime < unlockTime){
            StakedBalance storage newStake = bal.push();
            newStake.amount = _amount;
            newStake.unlockTime = unlockTime;
        }
        else{
            bal[index-1].amount = bal[index-1].amount + _amount;
        }
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;

        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender){
        require(_amount > 0, "amount = 0");
        require(balanceOf[msg.sender] > _amount, "Low Balance");
        if(coolDownPeriodStatus(msg.sender)){       
        uint256 totalClaimableReward;
        uint256 totalPenaltyReward;
        uint256 percentage;
        uint256 remaining = _amount;
        StakedBalance[] storage bal = stakeDetails[msg.sender];
        for(uint i=0; i< bal.length; i++) {
            if(remaining == 0){
                break;
            }
            uint256 stakedAmount = bal[i].amount;
            if(stakedAmount >= remaining){
               percentage = (stakedAmount * 1e18)/remaining;
            }
            else{
                percentage = 1e18;
            }
            uint256 penaltyRewards;
            uint256 rewardsAmount = rewards[msg.sender];
            uint256 timeStaked = bal[i].unlockTime - block.timestamp;
            uint256 stakedTimeRewards = rewardRate * timeStaked;                    
            if(bal[i].unlockTime > block.timestamp){
                penaltyRewards = (rewardsAmount * percentage)/1e18;
                totalPenaltyReward += penaltyRewards;
                rewards[msg.sender] = rewardsAmount - penaltyRewards;
            }
            else{
                totalClaimableReward += rewardsAmount;
                rewards[msg.sender] = 0;
            }
            if(remaining < stakedAmount){
                bal[i].amount -= remaining;
                remaining = 0;
                break;
            }
            else {
                remaining -= stakedAmount;
                delete bal[i];
            }
        }
       
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        if(totalPenaltyReward>0){
            rewardsToken.mint(owner, totalPenaltyReward);
            console.log("rewards minted", totalPenaltyReward);
            //rewardsToken.transfer(owner, totalPenaltyReward);
        }
        if(totalClaimableReward>0){
            //rewardsToken.transfer(msg.sender, totalClaimableReward);
            rewardsToken.mint(msg.sender, totalClaimableReward);
            emit RewardPaid(
                    msg.sender,
                    address(rewardsToken),
                    totalClaimableReward
                );
        }
        
        // _lastWithdrawalTime[msg.sender] = block.timestamp;
        // lastWithdrawTime = block.timestamp;
        emit Withdrawn(msg.sender, _amount);
        }
        
    }

    
    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function claim() public updateReward(msg.sender){
        uint256 totalAccumlatedRewards = rewards[msg.sender];               
            if (totalAccumlatedRewards > 0) {
                rewards[msg.sender] = 0;
                rewardsToken.mint(
                    msg.sender,
                    totalAccumlatedRewards
                );
                emit RewardPaid(
                    msg.sender,
                    address(rewardsToken),
                    totalAccumlatedRewards
                );
            }
    }


    function checkBalance(
        address _userAddress,
        uint256 _index
    )
        external
        view
        returns (
            uint256 _stakedAmount,
            uint256 _unlockTime
        )
    {
        return (
            stakeDetails[_userAddress][_index].amount,
            stakeDetails[_userAddress][_index].unlockTime
        );
    }
   
    function getStakeCount(address _account) external view returns (uint256) {
        return stakeDetails[_account].length;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IMintToken.sol";

contract StakingRewards{
    using SafeERC20 for IMintToken;
        
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
    
    mapping(address => bool) public isWithdrawn;

    mapping(address => uint256) private _lastWithdrawalTime;

    mapping(address => uint) public balanceOf;
    mapping(address => uint) public lastStake;
    mapping(address => uint) public lastUnlockedStake;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    
    uint256 public constant coolDownPeriod = 2 days;

    // Total supply
    uint public totalSupply;
    
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


    /**
     * @notice It returns reward Per token value
     */
    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (rewardRate * (block.timestamp - updatedAt) * 1e18) /
            totalSupply;
    }

    /**
    @notice User can stake tokens
    @param _amount amount of tokens to stake
    */
    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        lastStake[msg.sender] = block.timestamp;
        lastUnlockedStake[msg.sender] = block.timestamp + lockDuration;
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;

        emit Staked(msg.sender, _amount);
    }


    /**
     * @notice This function withdraws the staked Tokens. Penalty is applied if last stake is still
     * locked. Penalty is calculated based on time duration of total balance staked.
     * @param _amount amount of tokens to withdraw
     */
    
    function withdraw(uint256 _amount) external updateReward(msg.sender){
        require(_amount > 0, "amount = 0");
        require(balanceOf[msg.sender] > _amount, "Low Balance");
        _startCooldownTimer(msg.sender);
        require(block.timestamp > _lastWithdrawalTime[msg.sender], "Timer not completed");   
        uint256 percentage;
        uint256 lastStakeTime = lastStake[msg.sender];
        uint256 totalStakeBalance = balanceOf[msg.sender];
        if((lastStakeTime + lockDuration) > block.timestamp){
            //if last stake is locked
            uint256 timeStaked = block.timestamp - lastStakeTime;
            percentage = (_amount * timeStaked)/lastUnlockedStake[msg.sender];
            uint256 remaining = _amount - percentage;
            stakingToken.transfer(owner, percentage);
            stakingToken.transfer(msg.sender, remaining);

        }
        else{
            //if last stake is also unlocked
            stakingToken.transfer(msg.sender, _amount);
        } 
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
       
        isWithdrawn[msg.sender] = false;
        _lastWithdrawalTime[msg.sender] = 0;
        emit Withdrawn(msg.sender, _amount);

    }
    
    /**
     * @notice Calculate the total reward tokens earned
     * @param _account account address
     */
    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    /**
     * @notice User can claim all the reward tokens 
     */
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
    
    /**
     * @notice set cooldown timer
     * @param _account account address
     */
    function _startCooldownTimer(address _account) internal {
        if(isWithdrawn[_account] == false){
         _lastWithdrawalTime[_account] = block.timestamp + coolDownPeriod;
         isWithdrawn[_account] = true;
        }
    }

}

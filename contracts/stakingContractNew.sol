// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMintToken.sol";
import "./interfaces/IUniswapRouter.sol";
import "hardhat/console.sol";

contract StakingRewardsNew is ReentrancyGuard{
    using SafeERC20 for IMintToken;
        
    IERC20 public immutable stakingToken;
    IMintToken public immutable rewardsToken;

    address public owner;
    
    address private _wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public constant rewardDuration = 86400;
    uint256 public constant lockDuration = 10 minutes;


    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    
    // Reward to be paid out per second
    //345600 tokens to be paid out in 86400 seconds 
    uint public constant rewardRate = 4 * 1e18;
    
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;

    mapping(address => uint256) private _coolDownTime;

    mapping(address => uint) public balanceOf;
    mapping(address => uint) public lastStake;
    
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    
    uint256 public constant coolDownPeriod = 5 minutes;

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
    event Cooldown(address user);


    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
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
     * @notice set cooldown timer first before withdrawal
     */
    function cooldown() external {
    require(balanceOf[msg.sender] != 0, 'No tokens staked');
    _coolDownTime[msg.sender] = block.timestamp;

    emit Cooldown(msg.sender);
   }

    /**
    @notice User can stake tokens
    @param _amount amount of tokens to stake
    */
    function stake(uint _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        lastStake[msg.sender] = block.timestamp;
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Staked(msg.sender, _amount);
    }


    /**
     * @notice This function withdraws the staked Tokens. Penalty is applied if last stake is still
     * locked. Penalty is calculated based on time duration of total balance staked.
     * @param _amount amount of tokens to withdraw
     */
    
    function withdraw(uint256 _amount) external nonReentrant updateReward(msg.sender){
        require(_amount > 0, "amount should be greater than zero");
        require(balanceOf[msg.sender] >= _amount, "Low Balance");
        require(_coolDownTime[msg.sender] > 0, "Set cooldown timer First");
        uint256 cooldownStartTimestamp = _coolDownTime[msg.sender];       
        require(block.timestamp > cooldownStartTimestamp + coolDownPeriod, "Timer not completed");   
        uint256 percentage;
        uint256 lastStakeTime = lastStake[msg.sender];
        uint256 totalStakeTime = lastStakeTime + lockDuration;
        if(totalStakeTime > block.timestamp){
            //if last stake is locked
            uint256 timeStaked = block.timestamp - lastStakeTime;
            percentage = (_amount * timeStaked)/totalStakeTime;
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
        _coolDownTime[msg.sender] = 0;
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
    function claim() public nonReentrant updateReward(msg.sender){
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
     * 
     * @notice User can swap Eth for staking Token
     */
    function buyDotToken(
        uint256 _amount
    ) external payable returns (uint amountOut) {
        //require(msg.value >0, "infsufficient eth value");
        address[] memory path;
        path = new address[](2);
        path[0] = _wethAddress;
        path[1] = address(stakingToken);

        uint[] memory _amountOutMin = IUniswapV2Router(_routerAddress)
            .getAmountsOut(_amount, path);
        
        // console.log("amount out zero", _amountOutMin[0]);
        // console.log("amount out one", _amountOutMin[1]);

        
        //consider slippage    
        uint256 amountOutMin = (_amountOutMin[1] * 97) / 100;

        uint256[] memory amounts = IUniswapV2Router(_routerAddress)
            .swapExactETHForTokens{value: _amount}(
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 100
        );

        return amounts[1];
    }

    /**
     * @notice Function swaps staking token for Eth, considering user has some staking token
     * @param _amount amount of staking tokens User want to sell
     */
    function sellDotToken(
        uint256 _amount
    ) external returns (uint amountOut) {
        require(_amount > 0, "Enter a positive token Amount");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        IERC20(stakingToken).approve(_routerAddress, _amount);
        
        address[] memory path;
        path = new address[](2);
        path[0] = address(stakingToken);
        path[1] = _wethAddress;

        uint[] memory _amountOutMin = IUniswapV2Router(_routerAddress)
            .getAmountsOut(_amount, path);
        
        //consider slippage    
        uint256 amountOutMin = (_amountOutMin[1] * 97) / 100;

        uint256[] memory amounts = IUniswapV2Router(_routerAddress).swapExactTokensForETH(
            _amount, 
            amountOutMin, 
            path, 
            msg.sender, 
            block.timestamp + 100);

        return amounts[1];
    }

    function addLiquidityEth(uint256 _amount) external payable returns (uint _amountA, uint _amountETH, uint _liquidity){
        require(_amount > 0, "Enter a positive token Amount");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakingToken.approve(_routerAddress, _amount);
        (uint256 amountA, uint256 amountETH, uint256 liquidity) = IUniswapV2Router(_routerAddress)
        .addLiquidityETH{value: msg.value}(
            address(stakingToken),
            _amount,
            1,
            msg.value,
            address(this),
            block.timestamp + 500
        );
        // console.log("amount a", amountA);
        // console.log("amount eth", amountETH);
        // console.log("liquidity", liquidity);
        _amountA = amountA;
        _amountETH = amountETH;
        _liquidity = liquidity;
        
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
    
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract TimeToken is Ownable{
  using Address for address;
  string public name = "Time Token";
  string public symbol = "tToken";
  uint8 public decimals = 18;
  uint256 public totalSupply;
  

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  event LockTokens(address fromAccount, address toAccount, uint256 amount, uint256 releaseTime);

  constructor() Ownable(){

  }

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  mapping(address => uint256) public updatedAt;
  mapping(address => uint256) public _finishAt;
  mapping(address => uint256) public _rewardRate;

  function mint(uint256 _amount) external onlyOwner {
    totalSupply += _amount;
    balanceOf[msg.sender] += _amount;
  }


  function initateTransfer(uint256 _amount, uint256 _duration, address _to) public{
    if(block.timestamp > _finishAt[_to]){
        _rewardRate[_to] = _amount/_duration;
    }
    else{
        uint256 remainingRewards = (_finishAt[_to] - block.timestamp) * _rewardRate[_to];
        _rewardRate[_to] = (_amount + remainingRewards)/_duration;
    }

    require(_rewardRate[_to] > 0, "Not a valid Reward Rate");
    require(_rewardRate[_to] * _duration <= balanceOf[msg.sender], "Not enough Tokens");

    _transfer(address(this), _amount);


    _finishAt[_to] = block.timestamp + _duration;
    updatedAt[_to] = block.timestamp;
    emit LockTokens(msg.sender, _to, _amount, _finishAt[_to]);
  }



  function claim() external {
    uint256 totalAccumalated;
    if(block.timestamp < _finishAt[msg.sender]){
        totalAccumalated = _rewardRate[msg.sender] * (block.timestamp - updatedAt[msg.sender]);
    }
    else{
        totalAccumalated = _rewardRate[msg.sender] * (_finishAt[msg.sender] - updatedAt[msg.sender]);
        _rewardRate[msg.sender] = 0;
    }
    require(totalAccumalated <= balanceOf[address(this)], "Not enough balance left");
    
    if(totalAccumalated >0){  
        balanceOf[address(this)] -= totalAccumalated;
        balanceOf[msg.sender] += totalAccumalated;
        totalSupply -= totalAccumalated;
    }
    updatedAt[msg.sender] = block.timestamp;

  }

  function claimableAmount() external view returns(uint256 totalAccumalated){
    if(block.timestamp < _finishAt[msg.sender]){
        totalAccumalated = _rewardRate[msg.sender] * (block.timestamp - updatedAt[msg.sender]);
    }
    else{
        totalAccumalated = _rewardRate[msg.sender] * (_finishAt[msg.sender] - updatedAt[msg.sender]);
    }
  }


  function _transfer(address _to, uint256 _value) private {
    require(_to != address(0), "Invalid recipient address");
    require(_value > 0 && _value <= balanceOf[msg.sender], "Invalid token transfer amount");  
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }

  function approve(address _spender, uint256 _value)
    public
    returns (bool success)
  {
    require(_spender != address(0), "Not a valid Address");
    allowance[msg.sender][_spender] += _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to
  ) public returns (bool success) {
    require(_to != address(0), "Invalid recipient address");
    uint totalAccumalated;
    if(block.timestamp < _finishAt[_to]){
        totalAccumalated = _rewardRate[_to] * (block.timestamp - updatedAt[_to]);
    }
    else{
        totalAccumalated = _rewardRate[_to] * (_finishAt[_to] - updatedAt[_to]);
        _rewardRate[_to] = 0;
    }
    require(totalAccumalated > 0 && totalAccumalated <= balanceOf[_from], "Invalid token transfer amount");
    require(totalAccumalated <= allowance[_from][msg.sender], "Insufficient allowance");   
    balanceOf[_from] -= totalAccumalated;
    balanceOf[_to] += totalAccumalated;
    allowance[_from][_to] -= totalAccumalated;
    updatedAt[_to] = block.timestamp;
    emit Transfer(_from, _to, totalAccumalated);
    return true;
  }


}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

contract NewToken is Ownable{
  using Address for address;
  string public name = "New Token";
  string public symbol = "nToken";
  uint8 public decimals = 18;
  uint256 public totalSupply;
  

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  //mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  mapping(address => bool) public isAllowed;
  mapping(address => uint256) public locked;
  mapping(address => uint256) public unlocked;

  function mint() external payable {
    require(msg.value >0, "Enter valid eth amount");
    uint256 tokenAmount = msg.value * 2;
    totalSupply += tokenAmount;
    //balanceOf[msg.sender] += tokenAmount;
    locked[msg.sender] += tokenAmount;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    //require(balanceOf[msg.sender] >= _value, "insufficient balance");
    if(isAllowed[_to]){
      //require(_value <= locked[msg.sender], "insufficent locked tokens to transfer");
      uint256 totalLockedToken = locked[msg.sender];
      uint256 totalUnlockedTokens = unlocked[msg.sender];
      require(totalLockedToken + totalUnlockedTokens >= _value, "insufficient tokens to transfer");
      if(totalLockedToken >= _value){
        locked[msg.sender] -= _value;
        locked[_to] += _value;
        //console.log("allowed if");
      }
      else{        
        uint256 difference = _value - totalLockedToken;
        //console.log("difference", difference);
        locked[msg.sender] -= totalLockedToken;
        //console.log("locked msg.sender", locked[msg.sender]);
        unlocked[msg.sender] -= difference;
        locked[_to] = locked[_to] + totalLockedToken + difference;
        // unlocked[msg.sender] -= difference;
        // unlocked[_to] += difference;
        //console.log("allowed else");
      }    
      //locked[msg.sender] -= _value;
      //console.log("locked msg sender", locked[msg.sender]);
      //locked[_to] += _value;
      //console.log("locked to", locked[_to]);
    }
    else{
        if(isAllowed[msg.sender]){
            require(_value <= locked[msg.sender], "insufficent locked tokens to transfer from");
            locked[msg.sender] -= _value;
            unlocked[_to] += _value;
        }
        else{
           require(_value <= unlocked[msg.sender], "insufficient unlocked tokens");
           unlocked[msg.sender] -= _value;  
           unlocked[_to] += _value;

        } 
        
    }
    // balanceOf[msg.sender] -= _value;
    // balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value)
    public
    returns (bool success)
  {
    allowance[msg.sender][_spender] += _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success) {
    //require(_value <= balanceOf[_from], "insufficient balance");
    require(_value <= allowance[_from][_to], "not allowed to transfer");
    if(isAllowed[_to]){
        uint256 totalLockedToken = locked[_from];
        uint256 totalUnlockedTokens = unlocked[_from];
        require(totalLockedToken + totalUnlockedTokens >= _value, "insufficient tokens to transfer");
        //require(_value <= locked[_from], "insufficent locked tokens to transfer");
        if(totalLockedToken >= _value){
        locked[_from] -= _value;
        locked[_to] += _value;
        //console.log("allowed if");
      }
      else{        
        uint256 difference = _value - totalLockedToken;
        locked[_from] -= totalLockedToken;
        unlocked[_from] -= difference;
        locked[_to] = locked[_to] + totalLockedToken + difference;
        //console.log("locked to", locked[_to]);
        //unlocked[_from] -= difference;
        //locked[_to] += difference;
        //console.log("allowed else");
      }
    }
    else{
        if(isAllowed[_from]){
            require(_value <= locked[_from], "insufficent locked tokens to transfer from");
            locked[_from] -= _value;
            unlocked[_to] += _value;
        }
        else{
            require(_value <= unlocked[_from], "insufficient unlocked tokens");
            unlocked[_from] -= _value;
            unlocked[_to] += _value;
        }
    }
    // balanceOf[_from] -= _value;
    // balanceOf[_to] += _value;
    allowance[_from][_to] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function allowContract(address _contractAddress) external onlyOwner{
        require(_contractAddress != address(0), "Not a valid Address");
        require(Address.isContract(_contractAddress) == true, "Not a contract Address");
        isAllowed[_contractAddress] = true;
    }
}
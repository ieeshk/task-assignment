// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

contract AToken is Ownable{
  using Address for address;
  string public name = "A Token";
  string public symbol = "aToken";
  uint8 public decimals = 18;
  uint256 public totalSupply;
  

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );
  event Burn(address _account, uint256 amount);

  event AddressVerified(address indexed account);
  event AddressUnverified(address indexed account);

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  mapping(address => bool) public verified;

  address[] public addressList;

  function mint(uint256 _amount) external onlyOwner {
    totalSupply += _amount;
    balanceOf[msg.sender] += _amount;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0), "Invalid recipient address");
    require(_value > 0 && _value <= balanceOf[msg.sender], "Invalid token transfer amount");
    if(!verified[_to]){
      uint256 burnAmount = (_value * 25)/100;
      balanceOf[msg.sender] -= burnAmount;
      totalSupply -= burnAmount;
      emit Burn(msg.sender, burnAmount);
      _value -= burnAmount;
      
    }
    
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    totalSupply -= _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
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
    address _to,
    uint256 _value
  ) public returns (bool success) {
      require(_to != address(0), "Invalid recipient address");
      require(_value > 0 && _value <= balanceOf[_from], "Invalid token transfer amount");
      require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
      if(!verified[_to]){
      uint256 burnAmount = (_value * 25)/100;
      balanceOf[msg.sender] -= burnAmount;
      totalSupply -= burnAmount;
      emit Burn(msg.sender, burnAmount);
      _value -= burnAmount;  
    }
    
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    totalSupply -= _value;   
    allowance[_from][_to] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }


    function verifyAddress(address[] memory _userAddress) external onlyOwner {
        for(uint i=0; i < _userAddress.length; i++){
          if(!verified[_userAddress[i]]){
            verified[_userAddress[i]] = true;
            emit AddressVerified(_userAddress[i]);
          }
          
        }  
    }

    function unVerifyAddress(address[] memory _userAddress) external onlyOwner {
        for(uint i=0; i < _userAddress.length; i++){
          if(verified[_userAddress[i]]){
            verified[_userAddress[i]] = false;
            emit AddressUnverified(_userAddress[i]);
          }
          
        }  
    }
}
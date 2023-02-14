// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract OneToken is ERC20, Ownable{
    using Address for address;

    event Mint(address indexed to, uint256 value);
    event Lock(address indexed owner, uint256 value);
    
    constructor() ERC20("One Token", "ONE") Ownable(){
    }

    mapping(address => uint256) public balances;
    //mapping(address => mapping(address => uint256)) public allowed;
    //mapping(address => bool) public locked;
    
    mapping(address => bool) public isAllowed;
    mapping(address => uint256) public locked;
    mapping(address => uint256) public unlocked;
    
    function mint() external payable {
        //for msg.value amount, we will mint twice tokens
        require(msg.value >0, "Enter valid eth amount");
        uint256 tokenAmount = msg.value * 2;
        _mint(msg.sender, tokenAmount);
        //all stored in balances are locked
        balances[msg.sender] += tokenAmount;
        //locked[msg.sender] = true;
        //totalSupply += tokenAmount;
        //userBalanceStatus[msg.sender].lockedTokens = tokenAmount;
        //userBalanceStatus[msg.sender].totalTokens = tokenAmount;

        emit Mint(msg.sender, tokenAmount);
    }

    function _transfer(address from, address to, uint256 amount) internal override{
        if(isAllowed[to]){
            locked[from] -= amount;
            unlocked[to] += amount;
            super._transfer(from, to, amount); 
        }
        else{
            locked[from] -= amount;
            super._transfer(from, to, amount);
        }

        // if(isAllowed[to]){
        //     unlocked[to] += amount;
        // }
        // locked[from] -= amount;
        // super._transfer(from, to, amount);

        
    }

    // function transfer(address _to, uint256 _value) public virtual override returns(bool){
    //     if(isAllowed[_to]){
    //         balances[msg.sender] -= _value;
    //         super._transfer(msg.sender, _to, _value); 
    //     }
    //     // else{

    //     // }
    //     //super._transfer(msg.sender, _to, _value); 
    //     return true;  
    // }

    // function approve(address _spender, uint256 _value) public override returns(bool) {
    //     allowed[msg.sender][_spender] = _value;
    //     emit Approval(msg.sender, _spender, _value);
    // }

    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool){
        // require(isAllowed[_to] == true, "Spender Address not allowed");
        // isLocked[_from] -= _value;
        // if(isAllowed[_to]){
        //     balances[msg.sender] -= _value;
        // }
        super._spendAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value); 
        return true; 

    }

    function allowContract(address _contractAddress) external onlyOwner{
        require(_contractAddress != address(0), "Not a valid Address");
        require(Address.isContract(_contractAddress) == true, "Not a contract Address");
        isAllowed[_contractAddress] = true;
    }


}
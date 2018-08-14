pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
/**
* @title Token
* This contracts contains the ERC20 token functions
*/
contract Token  {

    using SafeMath for uint256;

    /*Variables*/
    uint public total_supply;
    mapping(address => uint) internal balances;
    mapping(address => mapping (address => uint)) internal allowed;
    
    /*Events*/
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /*Functions*/
    /**
    * @dev Constructor that sets the passed value as the token to be mineable.
    */
    constructor() public{
        total_supply = 2**256 - 1;
        balances[address(this)] = total_supply;
    }
    
    /**
    * @dev Gets balance of owner specified
    * @param _owner is the owner address used to look up the balance
    * @return Returns the balance associated with the passed in _owner
    */
    function balanceOf(address _owner) public constant returns (uint bal) { 
        return balances[_owner]; 
    }

    /**
    * @dev Allows for a transfer of tokens to _to
    * @param _to The address to send tokens to
    * @param _amount The amount of tokens to send
    * @return true if transfer is successful
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to].add(_amount) > balances[_to]) {
            xfer(msg.sender,_to,_amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    * @dev Allows an address with sufficient spending allowance to send tokens on the behalf of _from
    * @param _from The address to send tokens from
    * @param _to The address to send tokens to
    * @param _amount The amount of tokens to send
    * @return true if transfer is successful
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to].add(_amount) > balances[_to]) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _amount;
            xfer(_from,_to,_amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    * @dev This function approves a _spender an _amount of tokens to use
    * @param _spender address
    * @param _amount amount the spender is being approved for
    * @return true if spender appproved successfully
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    * @param _owner address
    * @param _spender address
    * @return Returns the remaining allowance of tokens granted to the _spender from the _owner
    */
    function allowance(address _owner, address _spender) public view returns (uint) {
       return allowed[_owner][_spender]; }

    /**
    * @dev Getter for the total_supply of wrapped ether
    * @return total supply
    */
    function totalSupply() public constant returns (uint) {
       return total_supply;
    }

    /**
    * @dev Internal fuction used in tranferFrom that allows an address with 
    * sufficient spending allowance to send tokens on the behalf of _from
    * @param _from The address to send tokens from
    * @param _to The address to send tokens to
    * @param _amount The amount of tokens to send
    */
    function xfer(address _from, address _to, uint _amount) internal {
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

}


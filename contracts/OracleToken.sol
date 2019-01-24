pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./StakesandDisputes.sol";

/**
* @title Oracle token
* This where the oracle tokens are minted from  
* and miners are paid from
*/

contract OracleToken is Token, Oracle {

    using SafeMath for uint256;

    /*Variables*/
    string public constant name = "Proof-of-Work Oracle Token";
    string public constant symbol = "POWO";
    uint8 public constant decimals = 18;
    uint public devShare;
    address public stakes;
    address public owner;

    /*Events*/
    event Deployed(string _api,address _newOracle);
    
    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    constructor(address _stakes, uint _devShare) public{
        owner = msg.sender;
        stakes = _stakes;
        devShare = _devShare;
      
    }

    /**
    * @dev Allows for a transfer of tokens to the first 5 _miners that solve the challenge and 
    * updates the total_supply of the token(total_supply is saved in token.sol)
    * The function is called by the Oracle.retrievePayoutPool and Oracle.pushValue.
    * Only oracles that have this ProofOfWOrkToken address as their master contract can call this 
    * function
    * @param _miners The five addresses to send tokens to
    * @param _amount The amount of tokens to send to each address
    * @param _isMine is true if the timestamp has been mined and miners have been paid out
    */
    function batchTransfer(address[5] _miners, uint256[5] _amount, bool _isMine) public{
        require(address(this) == msg.sender);
        uint _paid;
        for (uint i = 0; i < _miners.length; i++) {
            if (balanceOf(address(this)) >= _amount[i]
            && _amount[i] > 0
            && balanceOf(_miners[i]).add(_amount[i]) > balanceOf(_miners[i])) {
                doTransfer(address(this),_miners[i],_amount[i]);
                _paid += _amount[i];
            }
        }
        if(_isMine){
            total_supply += _paid;
        }
    }

    /**
    * @dev Allows the Oracle.RetreiveData to transfer the fee paid to retreive
    * data back to this contract
    * @param _from address to transfer from
    * @param _amount to transfer
    * @return true after transfer 
    */
    function callTransfer(address _from,uint _amount) public returns(bool){
        require(address(this) == msg.sender);
        doTransfer(_from,address(this), _amount);
        return true;
    }

    /**
    * @dev Allows the stakesandDisputes.deposit to transfer the stake 
    * @param _from address to transfer from
    * @param _amount to transfer
    * @return true after transfer 
    */
    function stakeTransfer(address _from,uint _amount) external returns(bool){
        require(stakes == msg.sender);
        doTransfer(_from,stakes, _amount);
        return true;
    }

    /**
    * @dev Allows the Oracle.RetreiveData to transfer tokens to the owner
    * @param _to address to transfer to
    * @param _amount to transfer
    * @return true after transfer 
    */
    function devTransfer(address _to,uint _amount) public returns(bool){
        require(address(this) == msg.sender);
        doTransfer(address(this),_to, _amount);
        return true;
    }

    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }
}

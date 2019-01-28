pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./Oracle.sol";

/**
* @title Oracle token
* This where the oracle tokens are minted from  
* and miners are paid from
*/

contract OracleToken is Token{

    using SafeMath for uint256;

    /*Variables*/
    string public constant name = "Proof-of-Work Oracle Token";
    string public constant symbol = "POWO";
    uint8 public constant decimals = 18;
    uint public devShare;
    address public owner;
    //address public oracleAddress;
    uint public disputeFee;
    uint public minimumQuorum;
    uint public voteDuration;//3days the same as voting period


    event ChangeMinQuorum(uint _newMinimumQuorum);
    event ChangeVoteDuration(uint _newVotingDuration);
    event ChangeDisputeFee(uint _newDisputelFee);


    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    constructor() public{
        owner = msg.sender;
        devShare = 5;
        disputeFee = 1000;
        minimumQuorum = 40;
        voteDuration = 14;

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
    function batchTransfer(address[5] _miners, uint256[5] _amount, bool _isMine) internal {
        //require(msg.sender == oracleAddress);
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
    function callTransfer(address _from,uint _amount) internal returns(bool){
        //require(msg.sender == oracleAddress);
        doTransfer(_from,address(this), _amount);
        return true;
    }

    /**
    * @dev Allows the Oracle.RetreiveData to transfer tokens to the owner
    * @param _to address to transfer to
    * @param _amount to transfer
    * @return true after transfer 
    */
    function devTransfer(address _to,uint _amount) internal returns(bool){
        //require(msg.sender == oracleAddress);
        doTransfer(address(this),_to, _amount);
        return true;
    }

    /**
    * @dev  updates to minimum quorum 
    * @param _minimumQuorum for passing vote and executing disputeFee or stake transfer
    */
    function setMinimumQuorum(uint _minimumQuorum) public onlyOwner()  {
        if (_minimumQuorum == 0 ) _minimumQuorum = 1;
        minimumQuorum = _minimumQuorum;
        emit ChangeMinQuorum(minimumQuorum);
    }

    /**
    * @dev Updates the vote duration
    * @param _voteDuration in days
    */
    function setVoteDuration(uint _voteDuration) public onlyOwner()  {
        voteDuration = _voteDuration;
        emit ChangeVoteDuration(voteDuration);
    }
    /**
    * @dev Updates the dispute fee amount
    * @param _disputeFee fee amount in POWO tokens 
    */
    function setDisputeFee(uint _disputeFee) public onlyOwner()  {
        disputeFee = _disputeFee;
        emit ChangeDisputeFee(disputeFee);
    }




}

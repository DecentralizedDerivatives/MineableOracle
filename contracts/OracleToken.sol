pragma solidity ^0.5.0;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./Ownable.sol";


/**
* @title Oracle token
* This where the oracle tokens are minted from  
* and miners are paid from
*/

contract OracleToken is Token,Ownable{

    using SafeMath for uint256;

    /*Variables*/
    string public constant name = "Proof-of-Work Oracle Token";
    string public constant symbol = "POWO";
    uint8 public constant decimals = 18;
    uint public constant devShare = 5;
    uint public constant disputeFee = 1000;
    uint public constant minimumQuorum = 40;
    uint public constant voteDuration = 14;//3days the same as voting period

    event ChangeMinQuorum(uint _newMinimumQuorum);
    event ChangeVoteDuration(uint _newVotingDuration);
    event ChangeDisputeFee(uint _newDisputelFee);
}

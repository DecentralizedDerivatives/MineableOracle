/* pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol"; */

/**
* @title Stake voting
* This contract allows Oracle token holders to vote
* to add or delete oracles.
*/
/*casper, delegated proof of steak, 
https://github.com/PoSToken/PoSToken/blob/master/contracts/PoSToken.sol
....*/
/*are we voting on each aspect of the new oracle or just 
the new oracle api*/
 contract OracleVote is ProofOfWorkToken {

    using SafeMath for uint256; 

    /*Variables*/
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    address owner;
	
	    /***Variables***/
    uint public total_deposited_supply;
    uint public total_locked;
    uint public locked_limit;

    struct Details{
        uint amount;
        address owner;
        uint transferId;
    }
    
    /***Storage***/
    mapping(address => uint) deposited_balances;
 
    /*Modifiers*/
        modifier onlyOwner() {
         require(msg.sender == owner);
        _;
    }

    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }

    function voteRemove(address _remove) public onlyOwner {
        /*require only token holders can vote
        /*weigh their vote based on locked balance
        /*where are they locking?--bridge*/
        /*if vote for removing > against then*/
        removeOracle(_remove);
    }

    function voteAdd(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public onlyOwner {
        deployNewOracle(_api,_readFee, _timeTarget,_payoutStructure);
    }


}
 
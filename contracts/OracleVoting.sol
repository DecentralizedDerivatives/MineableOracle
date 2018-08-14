pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";

/**
* @title Stake voting
* This contract allows Oracle token holders to vote
* to add or delete oracles.
*/
contract OracleVote is ProofOfWorkToken {

    using SafeMath for uint256;

    /*Variables*/
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    struct OracleDetails {
        string API;
        address location;
    }
    address public dud_Oracle;

    OracleDetails[] public oracle_list;
    mapping(address => uint) oracle_index;
    address owner;
    
    /*Events*/
    event Deployed(string _api,address _newOracle);

    /*Modifiers*/
        modifier onlyOwner() {
         require(msg.sender == owner);
        _;
    }

    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }

/*casper, delegated proof of steak, ....*/
/*are we voting on each aspect of the new oracle or just 
the new oracle api*/
    function voteRemove(address _remove) public onlyOwner {
        removeOracle(_remove);
    }

    function voteAdd(address _add) public onlyOwner {
        deployNewOracle(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure);
    }


}

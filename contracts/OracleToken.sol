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
    address public oracleAddress;
    uint public disputeFee;
    uint public minimumQuorum;
    uint public voteDuration;//3days the same as voting period

    uint[] public disputesIds;
    mapping(uint => Dispute) public disputes;//disputeId=> Disputes
    mapping (uint => uint) public disputesIdsIndex;
    
    struct Dispute {
        address reportedMiner; //miner who alledgedly submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty;//miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        uint apiId;
        uint timestamp;
        uint value; //the value being disputed
        uint minExecutionDate; 
        uint numberOfVotes;
        uint quorum;
        uint  blockNumber;
        int tally;
        bool executed;
        bool disputeVotePassed;       
        mapping (address => bool) voted;
    }  

    /*Events*/
    event NewDispute(uint _DisputeID, uint _apiId, uint _timestamp);
    event Voted(uint _disputeID, bool _position, address _voter);
    event DisputeVoteTallied(uint _disputeID, int _result, uint _quorum, bool _active);
    event ChangeMinQuorum(uint _newMinimumQuorum);
    event ChangeVoteDuration(uint _newVotingDuration);
    event ChangeDisputeFee(uint _newDisputelFee);
    event DisputeLost(address _reportingParty, uint);
    event StakeLost(address _reportedMiner,uint);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    constructor(address _stakes, uint _devShare, uint _disputeFee, uint _minimumQuorum, uint _voteDuration, uint _minimumStake, uint _minimuStatkeTime) public{
        owner = msg.sender;
        devShare = _devShare;
        disputeFee = _disputeFee;
        minimumQuorum = _minimumQuorum;
        voteDuration = _voteDuration;

    }

    function setOracleAddress(address _oracleAddress) public onlyOwner{
        oracleAddress = _oracleAddress;
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
    function batchTransfer(address[5] _miners, uint256[5] _amount, bool _isMine) public {
        require(msg.sender == oracleAddress);
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
        require(msg.sender == oracleAddress);
        doTransfer(_from,address(this), _amount);
        return true;
    }


    /**
    * @dev Allows the Oracle.RetreiveData to transfer tokens to the owner
    * @param _to address to transfer to
    * @param _amount to transfer
    * @return true after transfer 
    */
    function devTransfer(address _to,uint _amount) public returns(bool){
        require(msg.sender == oracleAddress);
        doTransfer(address(this),_to, _amount);
        return true;
    }



/*****************Disputes and Voting Functions***************/
    /**
    * @dev Helps initialize a dispute by assigning it a disputeId 
    * when a miner returns a false on the validate array(in oracle.ProofOfWork) it sends the 
    * invalidated value information to POS voting
    * @param _apiId being disputed
    * @param _timestamp being disputed
    * @return the dispute Id
    */
    function initDispute(uint _apiId, uint _timestamp) external returns(uint){
        Oracle oracle = Oracle(oracleAddress);
        //get blocknumber for this value and check blocknumber - value.blocknumber < x number of blocks 10 or 144?
        uint _minedblock = oracle.getMinedBlockNum(_apiId, _timestamp);
        require(block.number- _minedblock >144 && oracle.isData(_apiId, _timestamp) && transfer(address(this), disputeFee));//anyone owning tokens can report bad values, would this transfer from OracleToken to Stake token?
        uint disputeId = disputesIds.length + 1;
        address _reportedMiner = oracle.getMedianMinerbyApiIdTimestamp(_apiId, _timestamp);
        Dispute storage disp = disputes[disputeId];//how long can my mapping be? why is timestamp blue?
        disputesIds.push(disputeId);
        disp.reportedMiner = _reportedMiner; 
        disp.reportingParty = msg.sender;
        disp.apiId = _apiId;
        disp.timestamp = _timestamp;
        disp.value = oracle.retrieveData(_apiId,_timestamp);  
        disp.minExecutionDate = now + voteDuration * 1 days; 
        disp.numberOfVotes = 0;
        disp.executed = false;
        disp.disputeVotePassed = false;
        disp.blockNumber = block.number;
        StakeInfo memory stakes = staker[_reportedMiner];
        stakes.current_state = 3;
        return disputeId;
        emit NewDispute(disputeId,_apiId,_timestamp );
    }

    /**
    * @dev Allows token holders to vote
    * @param _disputelId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(uint _disputeId, bool _supportsDispute) external returns (uint voteId) {
        Dispute storage disp = disputes[_disputeId];
        require(disp.voted[msg.sender] != true && balanceOf(msg.sender)>0);
        /*******freeze voters********************************/
        StakeInfo memory stakes = staker[msg.sender];
        stakes.current_state = 1;
        stakes.stakeAmt= balanceOf(msg.sender);
        /*******freeze voters********************************/
        disp.voted[msg.sender] = true;
        disp.numberOfVotes += 1;
        uint voteWeight = balanceOf(msg.sender);
        disp.quorum +=  voteWeight;
        if (_supportsDispute) {
            disp.tally = disp.tally + int(voteWeight);
        } else {
            disp.tally = disp.tally - int(voteWeight);
        }
        emit Voted(_disputeId,_supportsDispute,msg.sender);
        return voteId;
    }

    function voteUnfreeze(uint _disputeId) external {
        Dispute storage disp = disputes[_disputeId];
        require(disp.voted[msg.sender] == true && disp.executed == true);
        /*******Un-freeze voters********************************/
        StakeInfo memory stakes = staker[msg.sender];
        stakes.current_state = 2;
        stakes.stakeAmt= 0;
        /*******Un-freeze voters********************************/
    } 
    /**
    * @dev tallies the votes and executes if minimum quorum is met or exceeded.
    * @param _disputeId is the dispute id
    */
    function tallyVotes(uint _disputeId) external{
        Dispute memory disp = disputes[_disputeId];
        require(disp.executed == false);
        require(now > disp.minExecutionDate && !disp.executed); //Uncomment for production-commented out for testing 
        uint minQuorum = minimumQuorum;
         require(disp.quorum >= minQuorum); 
          if (disp.tally > 0 ) {
             //if vote is >0 (meaning the value reported was a "bad value"), tranfer the stake value to 
             //the first miner that reported the inconsistency.      
            StakeInfo memory stakes = staker[disp.reportedMiner];        
            stakes.current_state = 2;
            uint stakeAmt = stakes.stakeAmt;
            stakes.stakeAmt = 0;
            disputeTransfer(disp.reportedMiner,disp.reportingParty, stakeAmt);
            emit StakeLost(disp.reportedMiner, stakeAmt);
            
            disp.disputeVotePassed = true;
            Oracle(oracleAddress). updateDisputeValue(disp.apiId, disp.timestamp);
        } 
        else {
            disp.executed = true;
            disp.disputeVotePassed = false;
            transfer(disp.reportedMiner, disputeFee);
            emit DisputeLost(disp.reportingParty, disputeFee);
        }
        emit DisputeVoteTallied(_disputeId,disp.tally, disp.quorum, disp.disputeVotePassed); 
    }


    /**
    * @dev Propose updates to minimum quorum 
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
/*****************Disputes and Voting Functions***************/
    /**
    *@dev Get Dispute information
    *@param _propId to pull propType and prop passed
    */
    function getDisputeInfo(uint _disputeId) view public returns(uint, uint, uint,bool) {
        Dispute memory disp = disputes[_disputeId];
        return(disp.apiId, disp.timestamp, disp.value, disp.disputeVotePassed);
    }

    /**
    * @dev Gets length of array containing all disputeIds
    */
    function countDisputes() view public returns(uint) {
        return disputesIds.length;
    }

    /**
    * @dev getter function to get all disputessIds
    */
    function getDisputesIds() view public returns (uint[]){
        return disputesIds;
    }

    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }
}

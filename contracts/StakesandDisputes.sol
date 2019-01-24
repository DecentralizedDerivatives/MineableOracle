pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./OracleToken.sol";

/**
* @title Oracle token
* This where the oracle tokens are minted from  
* and miners are paid from
* TODO: get balance from oracletoken for voting
* add function to report false value and put up for voting on validity
*/

contract StakesandDisputes is StakeToken {

    using SafeMath for uint256;

    /*Variables*/
    enum StakeState {
        notStaked,
        started,
        ended
    }
    uint public disputeFee;
    uint public minimumQuorum;
    uint public voteDuration;//3days the same as voting period
    uint public minimumStake;//stake required to become a miner and/or vote on disputes in oracle tokens
    uint public minimumStakeTime;
    address public owner;
    address[] public stakers;
    mapping(address => uint) public stakersIndex;
    mapping(address => StakeInfo) public staker; 
    uint[] public disputesIds;
    mapping(uint => Dispute) public disputes;//disputeId=> Disputes
    mapping (uint => uint) public disputesIdsIndex;
    address public oracleToken;//oracle token address

    
    struct Dispute {
        address reportedMiner; //miner who alledgedly submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty;//miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        bytes32 apiId;
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

    struct StakeInfo {
        //Enum state of the stake
        StakeState current_state;
        uint startDate; //stake start date
        uint stakeAmt;
    }

    /*Events*/
    event NewDispute(bytes32 _DisputeID, string _api, uint _timestamp);
    event Voted(uint _disputeID, bool _position, address _voter);
    event DisputeVoteTallied(uint _disputeID, int _result, uint _quorum, bool _active);
    event ChangeMinQuorum(uint newMinimumQuorum);
    event ChangeVoteDuration(uint newVotingDuration);
    event ChangeDisputeFee(uint newDisputelFee);
    event NewStake(address _sender, uint _value);
    event StakeWithdrawn(address _sender, uint _value);
    event StakeExtended(address _sender, uint _startdate, uint _stakeAmt)
  
    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    constructor(address _oracleToken, uint _disputeFee, uint _minimumQuorum, uint _voteDuration, uint minimumStake, uint _minimuStatkeTime) public{
       disputeFee = _disputeFee;
       minimumQuorum = _minimumQuorum;
       voteDuration = _voteDuration;
       minimumStake = _minimumStake;
       minimumStakeTime = _minimumStakeTime;
       oracleToken = _oracleToken;
    }

    function depositStake(uint _deposit) public {
        OracleToken _oracle = OracleToken(oracleToken);
        require(_deposit >= minimumStake && _oracle.stakeTransfer(msg.sender, address(this), _deposit));
        total_supply = total_supply.add(_deposit);
        stakers.push(msg.sender);
        stakersIndex[msg.sender] = stakers.length;
        StakeInfo memory stakes = staker[msg.sender];
        stakes.current_state = 1;
        stakes.startDate = now - (now % 86400);
        stakes.stakeAmt= _deposit;
        tranfer(address(this), _deposit);
        emit NewStake(msg.sender, msg.value);
    }

    function withdrawStake() public {
        OracleToken _oracle = OracleToken(oracleToken);
        StakeInfo memory stakes = staker[msg.sender];
        _today = now - (now % 86400);
        require(_today - stakes.startDate >= minimumStakeTime && stakes.current_state = 1 && balanceOf[msg.sender] >= stakes.stakeAmt);
        stakes.current_state = 2;
        balanceOf[msg.sender] -= stakes.stakeAmt;
        total_supply = total_supply.sub(stakes.stakeAmt);
        _oracle.transfer(msg.sender, stakes.stakeAmt);
        emit StakeWithdrawn(msg.sender, stakes.stakeAmt);
        stakes.stakeAmt = 0;
    }

    function extendStake() public {
        StakeInfo memory stakes = staker[msg.sender];
        _today = now - (now % 86400);
        require(_today - stakes.startDate >= minimumStakeTime && stakes.current_state = 1 && balanceOf[msg.sender] >= stakes.stakeAmt);
        stakes.startDate = now - (now % 86400);
        emit StakeExtended(msg.sender, stakes.startDate, stakes.stakeAmt);
    }
/*******************Need to send _apiId and timestamp from Oracle.POW***********/
    /**
    * @dev Helps initialize a dispute by assigning it a disputeId 
    * when a miner returns a false on the validate array(in oracle.ProofOfWork) it sends the 
    * invalidated value information to POS voting
    * @param _apiId being disputed
    * @param _timestamp being disputed
    * @return the dispute Id
    */
    function initDispute(uint _apiId, uint _timestamp) external returns(uint){
        OracleToken _oracle = OracleToken(oracleToken);
        //get blocknumber for this value and check blocknumber - value.blocknumber < x number of blocks 10 or 144?
        require(_oracle.isData(_apiId, _timestamp) && _oracle.transfer(address(this), disputeFee));//anyone owning tokens can report bad values, would this transfer from OracleToken to Stake token?
        uint disputeId = disputesIds.length + 1;
        Dispute storage disp = disputes[disputeId];//how long can my mapping be? why is timestamp blue?
        disputesIds.push(disputeId);
        disp.reportedMiner = _oracle.getMedianMinerbyApiIdTimestamp(_apiId, _timestamp); 
        disp.reportingParty = msg.sender;
        disp.apiId = _apiId;
        disp.timestamp = _timestamp;
        disp.value = _oracle.retrieveData(_apiId,_timestamp);  
        disp.minExecutionDate = now + voteDuration * 1 days; 
        disp.numberOfVotes = 0;
        disp.executed = false;
        disp.disputeVotePassed = false;
        disp.blockNumber = block.number;
        return disputeId;
        emit NewDispute();
    }
/*******************Need to send _apiId and timestamp from Oracle.POW***********/
  /**
    * @dev Allows token holders to vote
    * @param _disputelId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(uint _disputeId, bool _supportsDispute) external returns (uint voteId) {
        Dispute storage disp = disputes[disputeId];
        require(disp.voted[msg.sender] != true && balanceOfAt(msg.sender,disp.blockNumber)>0);
        disp.voted[msg.sender] = true;
        disp.numberOfVotes += 1;
        uint voteWeight = balanceOfAt(msg.sender,disp.blockNumber);
        disp.quorum +=  voteWeight;
        if (_supportsDispute) {
            disp.tally = disp.tally + int(voteWeight);
        } else {
            disp.tally = disp.tally - int(voteWeight);
        }
        emit Voted(_distputeId,_supportsDispute,msg.sender);
        return voteId;
    }
    
    /**
    * @dev tallies the votes and executes if minimum quorum is met or exceeded.
    * @param _disputeId is the dispute id
    */
    function tallyVotes(uint _disputeId) external{
        Dispute storage disp = disputes[disputeId];
        require(disp.executed == false);
        require(now > disp.minExecutionDate && !disp.executed); //Uncomment for production-commented out for testing 
        uint minQuorum = minimumQuorum;
         require(disp.quorum >= minQuorum); 
         OracleToken _oracle = OracleToken(oracleToken);
          if (disp.tally > 0 ) {
             //if vote is >0 (meaning the value reported was a "bad value"), tranfer the stake value to 
             //the first miner that reported the inconsistency.      
            StakeInfo memory stakes = staker[reportedMiner];        
            stakes.current_state = 2;
            balanceOf[reportedMiner] -= stakes.stakeAmt;
            total_supply = total_supply.sub(stakes.stakeAmt);
            _oracle.transfer(reportingParty, stakes.stakeAmt);
            emit StakeLost(reportedMiner, stakes.stakeAmt);
            stakes.stakeAmt = 0;
            disp.disputeVotePassed = true;
        } 
        else {
            disp.executed = true;
            disp.disputeVotePassed = false;
            _oracle.transfer(reportedMiner, disputeFee);
            emit DisputeLost(reportingParty, disputeFee);
        }
        emit DisputeVoteTallied(_disputeId,prop.tally, disp.quorum, disp.disputeVotePassed); 
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

    /**
    *@dev Get Dispute information
    *@param _propId to pull propType and prop passed
    */
    function getDisputeInfo(uint _disputeId) view public returns(bytes32, uint, uint,bool) {
        return(Disputes[_disputeId].apiId, Disputes[_disputeId].timestamp, Disputes[_disputeId].value, disputes[_disputeId].disputeVotePassed);
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

pragma solidity ^0.5.0;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./Ownable.sol";

/**
 * @title Oracle Token
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * Includes functions for users to read data from, tip the miners and for miners to submit
 * values and get paid out from the master ProofOfWorkToken contract
 * TODO: Check miners are staked when submitting POW and add tipping at API level. 
 */
contract Disputable is Token,Ownable{
    using SafeMath for uint256;

    string public constant name = "Proof-of-Work Oracle Token";
    string public constant symbol = "POWO";
    uint8 public constant decimals = 18;
    uint constant public disputeFee = 1e18;
   /*Variables*/
    uint[] public disputesIds;
    
    mapping(uint => Dispute) public disputes;//disputeId=> Disputes
    mapping(bytes32 => uint) apiId;// api bytes32 gets an id = to count of requests array
    struct API{
        string apiString;//id to string api
        bytes32 apiHash;//hash of string
        uint index; //index in payoutPool
        uint payout;
        mapping(uint => uint) minedBlockNum;//[apiId][minedTimestamp]=>block.number
        mapping(uint => uint) values;//This the time series of values stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint => address[5]) minersbyvalue;  
    }
    mapping(uint => API) apiDetails;
 
    struct Dispute {
        address reportedMiner; //miner who alledgedly submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty;//miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        uint apiId;
        uint timestamp;
        uint value; //the value being disputed
        uint minExecutionDate; 
        uint numberOfVotes;
        uint  blockNumber;
        uint index; //index in dispute array
        int tally;
        bool executed;
        bool disputeVotePassed;       
        mapping (address => bool) voted;
    } 


    /*Events*/
    event NewDispute(uint _DisputeID, uint _apiId, uint _timestamp);
    event Voted(uint _disputeID, bool _position, address _voter);
    event DisputeVoteTallied(uint _disputeID, int _result, bool _active);
    event DisputeLost(address _reportingParty, uint);
    event StakeLost(address _reportedMiner,uint);

    /*****************Disputes and Voting Functions***************/
    /**
    * @dev Helps initialize a dispute by assigning it a disputeId 
    * when a miner returns a false on the validate array(in oracle.ProofOfWork) it sends the 
    * invalidated value information to POS voting
    * @param _apiId being disputed
    * @param _timestamp being disputed
    * @return the dispute Id
    */
    function initDispute(uint _apiId, uint _timestamp) external{
        API storage _api = apiDetails[_apiId];
        require(block.number- _api.minedBlockNum[_timestamp]<= 144 && _api.minedBlockNum[_timestamp] > 0);
        doTransfer(msg.sender,address(this), disputeFee);
        uint disputeId = disputesIds.length + 1;
        address[5] memory _miners = _api.minersbyvalue[_timestamp];
        disputes[disputeId] = Dispute({
            reportedMiner: _miners[2], 
            reportingParty: msg.sender,
            apiId: _apiId,
            timestamp: _timestamp,
            value: _api.values[_timestamp],  
            minExecutionDate: now + 7 days, 
            numberOfVotes: 0,
            executed: false,
            disputeVotePassed: false,
            blockNumber: block.number,
            tally: 0,
            index:disputeId
            });
        disputesIds.push(disputeId);
        staker[_miners[2]].current_state = 3;
        emit NewDispute(disputeId,_apiId,_timestamp );
    }

    /**
    * @dev Allows token holders to vote
    * @param _disputeId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(uint _disputeId, bool _supportsDispute) public{
        Dispute storage disp = disputes[_disputeId];
        uint voteWeight = balanceOfAt(msg.sender,disp.blockNumber);
        require(disp.voted[msg.sender] != true && voteWeight > 0 && staker[msg.sender].current_state != 3);
        disp.voted[msg.sender] = true;
        disp.numberOfVotes += 1;
        if (_supportsDispute) {
            disp.tally = disp.tally + int(voteWeight);
        } else {
            disp.tally = disp.tally - int(voteWeight);
        }
        emit Voted(_disputeId,_supportsDispute,msg.sender);
    }


    /**
    * @dev tallies the votes and executes if minimum quorum is met or exceeded.
    * @param _disputeId is the dispute id
    */
    function tallyVotes(uint _disputeId) public {
        Dispute storage disp = disputes[_disputeId];
        API storage _api = apiDetails[disp.apiId];
        require(disp.executed == false);
        require(now > disp.minExecutionDate); //Uncomment for production-commented out for testing 
        StakeInfo storage stakes = staker[disp.reportedMiner];  
          if (disp.tally != 0 ) { 
            stakes.current_state = 0;
            stakes.startDate = now -(now % 86400);
            uint _index = stakes.index;
            uint _lastIndex = stakers.length - 1;
            address _lastStaker = stakers[_lastIndex];
            stakers[_index] = _lastStaker;
            staker[_lastStaker].index = _index;
            stakers.length--;
            doTransfer(disp.reportedMiner,disp.reportingParty, stakeAmt);
            emit StakeLost(disp.reportedMiner, stakeAmt);
            disp.disputeVotePassed = true;
            _api.values[disp.timestamp] = 0;
        } 
        else {
            stakes.current_state = 1;
            disp.executed = true;
            disp.disputeVotePassed = false;
            transfer(disp.reportedMiner, disputeFee);
            emit DisputeLost(disp.reportingParty, disputeFee);
        }
        emit DisputeVoteTallied(_disputeId,disp.tally, disp.disputeVotePassed); 
    }

    /**
    *@dev Get Dispute information
    *@param _disputeId is the dispute id to check the outcome of
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
    function getDisputesIds() view public returns (uint[] memory){
        return disputesIds;
    }

    /**
    * @dev Gets blocknumber for mined timestamp 
    * @param _apiId to look up
    * @param _timestamp is the timestamp to look up blocknumber
    */
    function getMinedBlockNum(uint _apiId, uint _timestamp) public view returns(uint){
        return apiDetails[_apiId].minedBlockNum[_timestamp];
    }

    // /**
    // * @dev Gets the API struct variables that are not mappings
    // * @param _apiId to look up
    // */
    // function getApiVars(uint _apiId) external view returns(string memory, bytes32, uint, uint) {
    //     API memory _api = apiDetails[_apiId]; 
    //     return (_api.apiString, _api.apiHash, _api.index,_api.payout);
    // }

    // *
    // * @dev Gets the API struct variables that are mappings
    // * @param _apiId to look up
    // * @param _timestamp is the timestamp to look up
    
    // function getApiMappings(uint _apiId, uint _timestamp) external view returns(uint, address[5] memory){
    //     API storage _api = apiDetails[_apiId]; 
    //     return(_api.values[_timestamp],_api.minersbyvalue[_timestamp]);
    // }

    /**
    * @dev Gets the Dispute struct variables that are not mappings
    * @param _disputeId to look up
    */
/*    function getAllDisputeVars(uint _disputeId) external view returns(address, address, uint, uint, uint ,uint, uint, uint,int, bool){
        Dispute memory disp = disputes[_disputeId];
        return(disp.reportedMiner, disp.reportingParty, disp.apiId, disp.minExecutionDate, 
            disp.numberOfVotes,disp.quorum, disp.blockNumber, disp.index,disp.tally,disp.executed); 
    }*/
    
    /**
    * @dev Checks if an address voted in a dispute
    * @param _disputeId to look up
    * @param _address to look up
    */
    function didVote(uint _disputeId, address _address) external view returns(bool){
        return disputes[_disputeId].voted[_address];
    }

}
pragma solidity ^0.5.0;

import "./libraries/SafeMath.sol";
import "./OracleToken.sol";


/**
 * @title Oracle Token
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * Includes functions for users to read data from, tip the miners and for miners to submit
 * values and get paid out from the master ProofOfWorkToken contract
 * TODO: Check miners are staked when submitting POW and add tipping at API level. 
 */
contract Oracle is OracleToken{
    using SafeMath for uint256;
    /*Variables*/
    address owner;
    //address oracleTokenAddress;
    bytes32 public currentChallenge; //current challenge to be solved
    uint public timeOfLastProof; // time of last challenge solved
    uint public timeTarget; //The time between blocks (mined Oracle values)
    uint public count;//Number of miners who have mined this value so far

    uint public payoutTotal;//Mining Reward in PoWo tokens given to all miners per value
    uint public miningMultiplier;//This times payout total is the mining reward (it goes down each year)
    uint256 public difficulty; // Difficulty of current block
    uint[5] public payoutStructure;//The structure of the payout (how much uncles vs winner recieve)
    uint public requestFee;

    //API on q info
    bytes32 public apiOnQ; //string of current api with highest PayoutPool
    uint public apiOnQPayout; //value of highest api/timestamp PayoutPool
    uint public timeOnQ; //requested timestamp for api with highest Payout
    uint public miningApiId; //API being mined--updates with the ApiOnQ Id 
    
    uint[] public disputesIds;
    mapping(uint => Dispute) public disputes;//disputeId=> Disputes
    mapping (uint => uint) public disputesIdsIndex;

    //api to id- user sends in string api and the api gets an id
    mapping(bytes32 => uint) apiId;// api string gets an id = to count of requests array
    //id to string api
    mapping(uint => bytes32) api;//get the api string by looping through the apiIds
    uint[] public apiIds;
    mapping(uint => uint) public apiIdsIndex;
    
    mapping(uint => mapping(uint => uint)) payoutPool;//This is the payout pool for a given api/timestamp.
    //[apiId][minedTimestamp]=>block.number
    mapping(uint => mapping(uint => uint)) minedBlockNum;
    //apiId to minedTimestamp to value--get timestamp from request timestamp
    mapping(uint => mapping(uint => uint)) values;//This the time series of values stored by the contract where uint UNIX timestamp is mapped to value    
    //minedTimestamp to apiId
    mapping(uint => uint) public timeToApiId;
    uint[] public timestamps;
    //apiId to minedTimestamp to 5 miners
    mapping(uint => mapping(uint => address[5])) minersbyvalue;//This maps the UNIX timestamp to the 5 miners who mined that value
    //challenge to miner address to yes/no--where yes if they completed the channlenge
    mapping(bytes32 => mapping(address=>bool)) miners;//This is a boolean that tells you if a given challenge has been completed by a given miner
    

    Details[5] first_five;
    struct Details {
        uint value;
        address miner;
    }

    
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
    event Mine(address sender,address[5] _miners, uint[5] _values);//Emits upon a succesful value mine, indicates the msg.sender, 5 miners included in block, and the mined value
    event NewValue(uint _apiId, uint _time, uint _value);//Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event PoolPayout(address sender, uint _apiId, uint _timestamp, address[5] _miners, uint[5] _values);//Emits when a pool is paid out, who is included and the amount(money collected from reads)
    event ValueAddedToPool(address sender, uint _apiId, uint _value,uint _time);//Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event MiningMultiplierChanged(uint _newMultiplier);//Each year, the mining reward decreases by 1/5 of the initial mining reward
    event DataRetrieved(address _sender, uint _apiId, uint _timestamp, uint _value);//Emits when someone retireves data, this shows the msg.sender and the value retrieved
    event DataRequested(address _sender, bytes32 _api, uint _apiId, uint _timestamp);//Emits when someone retireves data, this shows the msg.sender, the party who gets the read, and the timestamp requested
    event NonceSubmitted(address _miner, string _nonce, uint _apiId, uint _value);//Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event NewAPIonQinfo(bytes32 _apiOnQ, uint _timeOnQ, uint _apiOnQPayout); //emits when a the payout of another request is higher after adding to the payoutPool or submitting a request
    event NewDispute(uint _DisputeID, uint _apiId, uint _timestamp);
    event Voted(uint _disputeID, bool _position, address _voter);
    event DisputeVoteTallied(uint _disputeID, int _result, uint _quorum, bool _active);
    event DisputeLost(address _reportingParty, uint);
    event StakeLost(address _reportedMiner,uint);


    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Constructor*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _timeTarget for the dificulty adjustment
    */
    constructor(uint _timeTarget) public{
        uint64[5] memory _payoutStructure = [1e18,5e18,10e18,5e18,1e18];
        timeOfLastProof = now - now  % _timeTarget;
        requestFee = 1;
        timeTarget = _timeTarget;
        miningMultiplier = 1e18;
        payoutStructure = _payoutStructure;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
        
    }


    /*Functions*/
    /**
    * @dev Proof of work is called by the miner when they submit the solution (proof of work and value)
    * @param nonce uint submitted by miner
    * @param _apiId the apiId being mined
    * @param value of api query
    * @return count of values sumbitted so far and the time of the last successful mine
    */
    function proofOfWork(string calldata nonce, uint _apiId, uint value) external returns (uint256,uint256) {
        require(getStakeAmt(msg.sender)>0);
        bytes32 _solution = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        bytes32 n = sha256(abi.encodePacked(ripemd160(abi.encodePacked(_solution))));
        require(uint(n) % difficulty == 0 && _apiId == miningApiId && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        uint _payoutMultiplier = 1;
        emit NonceSubmitted(msg.sender,nonce,_apiId,value);
        if(count == 5) { 
        uint _timediff = now - timeOfLastProof;
        int _diff = int(_timediff - timeTarget);
        if(count == 5) { 
            if (_diff != 0){
                difficulty = difficulty - _timediff/60;
            }

            uint i = (now - (now % timeTarget) - timeOfLastProof) / timeTarget;
            timeOfLastProof = now - (now % timeTarget);
            uint valuePool;
            while(i > 0){
                valuePool += payoutPool[_apiId][timeOfLastProof - (i - 1) * timeTarget];
                i = i - 1;
            }
            if(valuePool >= payoutTotal) {
                _payoutMultiplier = (valuePool + payoutTotal) / payoutTotal; //solidity should always round down
                payoutPool[_apiId][timeOfLastProof] = valuePool % payoutTotal;
            }
            else{
                payoutPool[_apiId][timeOfLastProof] = valuePool;
            }
            pushValue(_apiId, timeOfLastProof,_payoutMultiplier);
            minedBlockNum[_apiId][timeOfLastProof] = block.number;
            miningApiId = apiId[apiOnQ]; 
            timeToApiId[timeOfLastProof] = _apiId;
            timestamps.push(timeOfLastProof);
            count = 0;
            currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
         }
        return (count,timeOfLastProof); 
        }
    }

    /**
    * @dev Adds the _tip to the valuePool that pays the miners
    * @param _apiId the api Id the user want to add to the value pool
    * @param _timestamp is the timestamp that will be given the _tip once it is mined.
    * @param _tip amount to add to value pool
    * It should be the time stamp the user wants to ensure gets mined. They can do that 
    * by adding a _tip to insentivize the miners to submit a value for the time stamp. 
    */
    function addToValuePool (uint _apiId, uint _timestamp, uint _tip) public {  
        //OracleToken oracleToken = OracleToken(oracleTokenAddress);     
        require(callTransfer(msg.sender,_tip));
        uint _time;
        if(_timestamp == 0){
            _time = timeOfLastProof + timeTarget;
        }
        else{
            _time = _timestamp - (_timestamp % timeTarget);
        }
        payoutPool[_apiId][_time] = payoutPool[_apiId][_time].add(_tip);
        updateAPIonQ (_apiId, _timestamp);
        emit ValueAddedToPool(msg.sender,_apiId,_tip,_time);
    }
    
    /**
    @dev This contract uses this function to update APIonQ when requestData or addToValuePool are ran
    @param _apiId being requested
    @param _timestamp being requested
    */
    function updateAPIonQ (uint _apiId, uint _timestamp) internal {
        uint _payout = payoutPool[_apiId][_timestamp];
        if (_payout > apiOnQPayout ) {
            //update apiOnQ, apiOnPayout, and TimeOnQ
            apiOnQ = api[_apiId];
            apiOnQPayout = _payout;
            timeOnQ = _timestamp;
            emit NewAPIonQinfo(apiOnQ, timeOnQ, apiOnQPayout);
        } 
    }


    /**
    @dev The OracleToken cotract uses this function to "clear"(set to 0) a disputed value 
    that was found to be a "bad value"
    @param _apiId that was diputed
    @param _timestamp that was disputed
    */
    function updateDisputeValue(uint _apiId, uint _timestamp) internal {
        //require(msg.sender == oracleTokenAddress);
        values[_apiId][_timestamp] =0;
    }


    /**
    * @dev Request to retreive value from oracle based on timestamp
    * @param _api being requested be mined
    * @param _timestamp reqeusted to be mined
    * @param _requestGas amount the requester is willing to pay to be get on queue. Miners
    * mine the apiOnQ, or the api with the highest payout pool
    */
    function requestData(bytes32 _api, uint _timestamp, uint _requestGas) public returns(uint){
        require(apiId[_api] == 0 && _requestGas>= requestFee && callTransfer(msg.sender,_requestGas));
        uint _apiId=apiIds.length+1;
        apiIdsIndex[_apiId] = apiIds.length;
        apiIds.push(_apiId);
        apiId[_api] = _apiId;
        api[_apiId] = _api;
        uint _time = _timestamp - (_timestamp % timeTarget);
        payoutPool[_apiId][_time] = payoutPool[_apiId][_time].add(_requestGas);
        updateAPIonQ (_apiId, _timestamp);
        emit DataRequested(msg.sender,_api,_apiId,_timestamp);
        return _apiId;
    }

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _apiId being requested
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _apiId, uint _timestamp) public returns (uint) {
        require(isData(_apiId, _timestamp));
        emit DataRetrieved(msg.sender, _apiId, _timestamp, values[_apiId][_timestamp]);
        return values[_apiId][_timestamp];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified apiId/_timestamp 
    * @param _apiId to look up
    * @param _timestamp is the timestampt to look up miners for
    */
    function getMinersByValue(uint _apiId, uint _timestamp) public view returns(address[5] memory){
        return minersbyvalue[_apiId][_timestamp];
    }

    /**
    * @dev Gets blocknumber for mined timestamp 
    * @param _apiId to look up
    * @param _timestamp is the timestamp to look up blocknumber
    */
    function getMinedBlockNum(uint _apiId, uint _timestamp) public view returns(uint){
        return minedBlockNum[_apiId][_timestamp];
    }

    /**
    * @dev This function tells you if a given challenge has been completed by a given miner
    * @param _challenge the challenge to search for
    * @param _miner address that you want to know if they solved the challenge
    * @return true if the _miner address provided solved the 
    */
    function didMine(bytes32 _challenge,address _miner) public view returns(bool){
        return miners[_challenge][_miner];
    }
    
    /**
    * @dev Checks if a value exists for the timestamp provided
    * @param _apiId to look up/check
    * @param _timestamp to look up/check
    * @return true if the value exists/is greater than zero
    */
    function isData(uint _apiId, uint _timestamp) public view returns(bool){
        return (values[_apiId][_timestamp] > 0);
    }

    /**
    * @dev Getter function for currentChallenge difficulty
    * @return current challenge, MiningApiID, level of difficulty
    */
    function getVariables() external view returns(bytes32, uint, uint){    
        return (currentChallenge,miningApiId,difficulty);
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    */
    function getLastQuery() external returns(uint,bool){
        uint _apiId = timeToApiId[timeOfLastProof];
        return (retrieveData(_apiId, timeOfLastProof),true);
    }

    /**
    * @dev Getter function for apiId based on timestamp. Only one value is mined per
    * timestamp and each timestamp can correspond to a different API. 
    * @param _timestamp to check APIId
    * @return apiId
    */
    function getApiForTime(uint _timestamp) external view returns(uint){    
        return timeToApiId[_timestamp];
    }

    /**
    * @dev Getter function for api based on apiID
    * @param _apiId the apiId to look up the api string
    * @return api string/bytes32
    */
    function getApi(uint _apiId) external view returns(bytes32){    
        return api[_apiId];
    }

    /**
    * @dev Getter function for apiId based on api
    * @param _api string to check if it already has an apiId
    * @return uint apiId
    */
    function getApiId(bytes32 _api) external view returns(uint){    
        return apiId[_api];
    }

    /**
    * @dev Getter function for all apiId's 
    * @return array of apiIds
    */
    function getAllApiIds() external view returns(uint[] memory){    
        return apiIds;
    }

    /**
    * @dev Getter function for the payoutPool total for the specified _apiId and _timestamp
    * If the _timestamp is not specified(_timestamp=0) it will return the total payoutPool
    * for the _timestamp being mined
    * @param _apiId to look up the total payoutPool value
    * @param _timestamp to look up the total payoutPool value 
    * @return the value of the total payoutPool
    */
    function getValuePoolAt(uint _apiId, uint _timestamp) external view returns(uint){
        if(_timestamp == 0){
            uint _time = timeOfLastProof.add(timeTarget);
            return payoutPool[_apiId][_time];
        }
        else{
            return payoutPool[_apiId][_timestamp];
        }
    }

    /**
    * @dev This function rewards the first five miners that submit a value
    * through the proofOfWork function and sorts the value as it is received 
    * so that the median value is 
    * given the highest reward
    * @param _apiId for the value being provided by the miners
    * @param _time is the time/date for the value being provided by the miner
    * @param _payoutMultiplier is calculated in the proofOfWork function to 
    * allocate the additional miner tip added via the addToValuePool function
    */
    function pushValue(uint _apiId, uint _time, uint _payoutMultiplier) internal {
        Details[5] memory a = first_five;
        uint[5] memory _payout;
        uint i;
        for (i = 1;i <5;i++){
            uint temp = a[i].value;
            address temp2 = a[i].miner;
            uint j = i;
            while(j > 0 && temp < a[j-1].value){
                a[j].value = a[j-1].value;
                a[j].miner = a[j-1].miner;   
                j--;
            }
            if(j<i){
                a[j].value = temp;
                a[j].miner= temp2;
            }
        }
        for (i = 0;i <5;i++){
            _payout[i] = payoutStructure[i]*_payoutMultiplier;
        }
        
        batchTransfer([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout,true);
        devTransfer(address(this),(payoutTotal * devShare / 100));
        values[_apiId][_time] = a[2].value;
        minersbyvalue[_apiId][_time] = [a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner];
        emit Mine(msg.sender,[a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout);
        emit NewValue(_apiId,timeOfLastProof,a[2].value);
    }

    /**
    * @dev This function gets the median value miner's address
    * @param _apiId for the value being looked up
    * @param _timestamp is the time/date for the value being looked up
    */
    function getMedianMinerbyApiIdTimestamp(uint _apiId, uint _timestamp) public view returns(address) {
        address[5] memory _miners = minersbyvalue[_apiId][_timestamp];
        address _miner = _miners[2];
        return _miner;
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
        //get blocknumber for this value and check blocknumber - value.blocknumber < x number of blocks 10 or 144?
        uint _minedblock = getMinedBlockNum(_apiId, _timestamp);
        require(block.number- _minedblock <= 144 && isData(_apiId, _timestamp) && transfer(address(this), disputeFee));
        uint disputeId = disputesIds.length + 1;
        address _reportedMiner = getMedianMinerbyApiIdTimestamp(_apiId, _timestamp);
        disputes[disputeId] = Dispute({
            reportedMiner: _reportedMiner, 
            reportingParty: msg.sender,
            apiId: _apiId,
            timestamp: _timestamp,
            value: retrieveData(_apiId,_timestamp),  
            minExecutionDate: now + voteDuration * 1 days, 
            numberOfVotes: 0,
            executed: false,
            disputeVotePassed: false,
            blockNumber: block.number,
            quorum: 0,
            tally: 0
            });
        disputesIds.push(disputeId);
        StakeInfo memory stakes = staker[_reportedMiner];
        stakes.current_state = 3;
        return disputeId;
        emit NewDispute(disputeId,_apiId,_timestamp );
    }

    /**
    * @dev Allows token holders to vote
    * @param _disputeId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(uint _disputeId, bool _supportsDispute) public returns (uint voteId) {
        Dispute storage disp = disputes[_disputeId];
        StakeInfo memory stakes = staker[msg.sender];
        uint voteWeight = balanceOfAt(msg.sender,disp.blockNumber);
        require(disp.voted[msg.sender] != true && voteWeight > 0 && stakes.current_state != 3);
        disp.voted[msg.sender] = true;
        disp.numberOfVotes += 1;
        disp.quorum +=  voteWeight;
        if (_supportsDispute) {
            disp.tally = disp.tally + int(voteWeight);
        } else {
            disp.tally = disp.tally - int(voteWeight);
        }
        emit Voted(_disputeId,_supportsDispute,msg.sender);
        return voteId;
    }


    /**
    * @dev tallies the votes and executes if minimum quorum is met or exceeded.
    * @param _disputeId is the dispute id
    */
    function tallyVotes(uint _disputeId) public {
        Dispute memory disp = disputes[_disputeId];
        require(disp.executed == false);
        require(now > disp.minExecutionDate && !disp.executed); //Uncomment for production-commented out for testing 
        uint minQuorum = minimumQuorum;
         require(disp.quorum >= minQuorum); 
          if (disp.tally > 0 ) { 
            StakeInfo memory stakes = staker[disp.reportedMiner];        
            stakes.current_state = 2;
            uint stakeAmt = stakes.stakeAmt;
            stakes.stakeAmt = 0;
            disputeTransfer(disp.reportedMiner,disp.reportingParty, stakeAmt);
            emit StakeLost(disp.reportedMiner, stakeAmt);
            disp.disputeVotePassed = true;
            updateDisputeValue(disp.apiId, disp.timestamp);
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
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }
}
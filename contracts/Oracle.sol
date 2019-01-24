pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";

/**
 * @title Oracle Token
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * Includes functions for users to read data from, tip the miners and for miners to submit
 * values and get paid out from the master ProofOfWorkToken contract
 */
contract Oracle {
    using SafeMath for uint256;
    /*Variables*/
    bytes32 public currentChallenge; //current challenge to be solved
    uint public devShare;//devShare of contracts
    uint public timeOfLastProof; // time of last challenge solved
    uint public timeTarget; //The time between blocks (mined Oracle values)
    uint public count;//Number of miners who have mined this value so far

    uint public payoutTotal;//Mining Reward in PoWo tokens given to all miners per value
    uint public miningMultiplier;//This times payout total is the mining reward (it goes down each year)
    uint256 public difficulty; // Difficulty of current block
    uint[5] public payoutStructure;//The structure of the payout (how much uncles vs winner recieve)

    //API on q info
    bytes32 public apiOnQ; //string of current api with highest PayoutPool
    uint public apiOnQPayout; //value of highest api/timestamp PayoutPool
    uint public timeOnQ; //requested timestamp for api with highest Payout
    uint public miningApiId; //API being mined--updates with the ApiOnQ Id 
    
    //api to id- user sends in string api and the api gets an id
    mapping(bytes32 => uint) as apiId;// api string gets an id = to count of requests array so apiID[string] = requestsID.length
    //id to string api
    mapping(uint => bytes32) as api;//get the api string by looping through the apiIds
    uint[] public apiIds;
    mapping(uint => uint) public apiIdsIndex;
    
    //[apiId][timestamp]=>requestId = requestsId[].length
    //mapping(uint => mapping(uint => uint)) requestID;
    //[apiId][timestamp]=>payoutPool
    mapping(uint => mapping(uint => uint)) payoutPool;//This is the payout pool for a given api/timestamp.
    //[apiId][minedTimestamp]=>block.number
    mapping(uint => mapping(uint => uint)) minedBlockNum;
    //apiId to minedTimestamp to value--get timestamp from request timestamp
    mapping(uint => mapping(uint => uint)) values;//This the time series of values stored by the contract where uint UNIX timestamp is mapped to value    
    //minedTimestamp to apiId
    mapping(uint => uint) public timeToApiId;
    uint[] public timestamps;
    //apiId to minedTimestamp to 5 miners
    mapping(uint => mapping(uint => address[5]) minersbyvalue;//This maps the UNIX timestamp to the 5 miners who mined that value
    //challenge to miner address to yes/no--where yes if they completed the channlenge
    mapping(bytes32 => mapping(address=>bool)) miners;//This is a boolean that tells you if a given challenge has been completed by a given miner
    
    Details[5] first_five;
    struct Details {
        uint value;
        address miner;
    }

    /*Events*/
    event Mine(address sender,address[5] _miners, uint[5] _values);//Emits upon a succesful value mine, indicates the msg.sender, 5 miners included in block, and the mined value
    event NewValue(uint _apiId, uint _time, uint _value);//Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event PoolPayout(address sender, uint _apiId, uint _timestamp, address[5] _miners, uint[5] _values);//Emits when a pool is paid out, who is included and the amount(money collected from reads)
    event ValueAddedToPool(address sender, uint _apiId, uint _value,uint _time);//Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event MiningMultiplierChanged(uint _newMultiplier);//Each year, the mining reward decreases by 1/5 of the initial mining reward
    event DataRetrieved(address _sender, uint _apiId, uint _timestamp, uint _value);//Emits when someone retireves data, this shows the msg.sender and the value retrieved
    event DataRequested(address _sender, bytes32 _api, uint _apiId, uint _timestamp);//Emits when someone retireves data, this shows the msg.sender, the party who gets the read, and the timestamp requested
    event NonceSubmitted(address _miner, string _nonce, uint _value);//Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event NewAPIonQinfo(bytes32 _apiOnQ, uint _timeOnQ, uint _apiOnQPayout); //emits when a the payout of another request is higher after adding to the payoutPool or submitting a request

    /*Constructor*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master ProofOfWorkToken.address
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    * @param _devShare for dev
    */
    constructor(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure, uint _devShare) public{
        require(_timeTarget > 60);
        timeOfLastProof = now - now  % _timeTarget;
        devShare = _devShare;
        requestFee = _requestFee;
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
    * @param value of api query
    * @return count of values sumbitted so far and the time of the last successful mine
    */
    function proofOfWork(string nonce, uint apiId, uint value) external returns (uint256,uint256) {
        bytes32 _solution = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        uint _rem = uint(_solution) % 3;
        bytes32 n;
        if(_rem == 2){
            n = keccak256(abi.encodePacked(_solution));
        }
        else if(_rem ==1){
            n = sha256(abi.encodePacked(_solution));
        }
        else{
            n = keccak256(abi.encodePacked(ripemd160(abi.encodePacked(_solution))));
        }

        require(uint(n) % difficulty == 0 && apiId == miningApiId && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        uint _payoutMultiplier = 1;
        emit NonceSubmitted(msg.sender,nonce,apiId,value);
        if(count == 5) { 
        uint _timediff = now - timeOfLastProof;
        if(count == 5) { 
            if (_timediff < (timeTarget){
                difficulty = difficulty + _timediff/60;
            }
            else if (_timediff > timeTarget && difficulty > 1){
                difficulty--;
            }
            
            uint i = (now - (now % timeTarget) - timeOfLastProof) / timeTarget;
            timeOfLastProof = now - (now % timeTarget);
            uint valuePool;
            while(i > 0){
                valuePool += payoutPool[apiId][timeOfLastProof - (i - 1) * timeTarget];
                i = i - 1;
            }
            if(valuePool >= payoutTotal) {
                _payoutMultiplier = (valuePool + payoutTotal) / payoutTotal; //solidity should always round down
                payoutPool[apiId][timeOfLastProof] = valuePool % payoutTotal;
            }
            else{
                payoutPool[apiId][timeOfLastProof] = valuePool;
            }
            pushValue(apiId, timeOfLastProof,_payoutMultiplier);
            minedBlockNum[apiId][timeOfLastProof] = block.number;
            miningApiId = api[_apiOnQ]; 
            timeToApiId[timeOfLastProof] = apiId;
            timestamps.push(timeOfLastProof);
            count = 0;
            currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
         }
     return (count,timeOfLastProof); 
    }

    /**
    * @dev Adds the _tip to the valuePool that pays the miners
    * @param _tip amount to add to value pool
    * @param _timestamp is the timestamp that will be given the _tip once it is mined.
    * It should be the time stamp the user wants to ensure gets mined. They can do that 
    * by adding a _tip to insentivize the miners to submit a value for the time stamp. 
    */
    function addToValuePool(uint _apiId, uint _timestamp, uint _tip) public {       
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
    @dev use this function to update APIonQ via requestData or addToValuePool
    @param _apiId being requested
    @param _timestamp
    */
    function updateAPIonQ (uint _apiId, uint _timestamp) internal {
        _payout = getValuePoolAt(_apiId, _timestamp);
        if (_payout > apiOnQPayout ) {
            //update apiOnQ, apiOnPayout, and TimeOnQ
            apiOnQ = api[_apiId];
            apiOnQPayout = _payout;
            timeOnQ = _timestamp;
            emit NewAPIonQinfo(apiOnQ, timeOnQ, apiOnQPayout);
        } 
    }

    /**
    * @dev Retrieve payout from the data reads. It pays out the 5 miners.
    * @param _timestamp for which to retreive the payout from
    */
    function retrievePayoutPool(uint _apiId, uint _timestamp) public {
        uint _payoutMultiplier = payoutPool[_apiId][_timestamp] / payoutTotal;
        require (_payoutMultiplier > 0 && values[_apiId][_timestamp] > 0);
        uint[5] memory _payout = [payoutStructure[4]*_payoutMultiplier,payoutStructure[3]*_payoutMultiplier,payoutStructure[2]*_payoutMultiplier,payoutStructure[1]*_payoutMultiplier,payoutStructure[0]*_payoutMultiplier];
        batchTransfer(minersbyvalue[_apiId][_timestamp], _payout,false);
        emit PoolPayout(msg.sender, _apiId, _timestamp,minersbyvalue[_apiId][_timestamp], _payout);
    }

    /**
    * @dev Request to retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @param _party who gets the tokens
    */
    function requestData(bytes32 _api, uint _timestamp, uint _requestGas) public{
        require(apiId[_api] == 0 && _requestGas>= requestFee && callTransfer(msg.sender,_requestGas));
        uint _apiId=apiIds.length+1;
        apiIdsIndex[_apiId] = apiIds.length;
        apiIds.push(_apiId);
        apiId[_api] = _apiId;
        api[_apiId] = _api;
        _time = _timestamp - (_timestamp % timeTarget);
        payoutPool[_apiId][_time] = payoutPool[_apiId][_time].add(_requestGas);
        updateAPIonQ (_apiId, _timestamp);
        emit DataRequested(msg.sender,_api,_apiId,_timestamp);
    }

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _apiId, uint _timestamp) public returns (uint) {
        require(isData(_apiId, _timestamp));
        emit DataRetrieved(msg.sender,values[_apiId][_timestamp]);
        return values[_apiId][_timestamp];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified _timestamp 
    * @param _timestamp is the timestampt to look up miners for
    */
    function getMinersByValue(uint _apiId, uint _timestamp) public view returns(address[5]){
        return minersbyvalue[_apiId][_timestamp];
    }

    /**
    * @dev Gets blocknumber for mined timestamp 
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
    * @param _timestamp to retreive data/value from
    * @return true if the value exists/is greater than zero
    */
    function isData(uint _apiId, uint _timestamp) public view returns(bool){
        return (values[_apiId][_timestamp] > 0);
    }

    /**
    * @dev Getter function for currentChallenge difficulty
    * @return current challenge and level of difficulty
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
    * @dev Getter function for api based on apiID
    * @return current challenge and level of difficulty
    */
    function getApiForTime(uint _timestamp) external view returns(uint){    
        return timeToApiId[_timestamp];
    }

    /**
    * @dev Getter function for api based on apiID
    * @return current challenge and level of difficulty
    */
    function getApi(uint _apiId) external view returns(bytes32){    
        return api[apiId];
    }

    /**
    * @dev Getter function for apiId based on api
    * @return current challenge and level of difficulty
    */
    function getApiId(bytes32 _api) external view returns(uint){    
        return apiId[_api];
    }

    /**
    * @dev Getter function for all apiId's 
    * @return current challenge and level of difficulty
    */
    function getAllApiIds() external view returns(uint[]){    
        return apiIds;
    }

    /**
    * @dev Getter function for the payoutPool total for the specified _timestamp
    * If the _timestamp is not specified(_timestamp=0) it will return the total payoutPool
    * for the _timestamp being mined
    * @param _timestamp to look up the total payoutPool value 
    * @return the value of the total payoutPool
    */
    function getValuePoolAt(uint _apiId, uint _timestamp) external view returns(uint){
        if(_timestamp == 0){
            uint _time = timeOfLastProof.add(timeTarget);
            return payoutPool[_apiId][_time];
        }
        else{
            return payoutPool[apiId][_timestamp];
        }
    }

    /**
    * @dev This function rewards the first five miners that submit a value
    * through the proofOfWork function and sorts the value as it is received 
    * so that the median value is 
    * given the highest reward
    * @param _time is the time/date for the value being provided by the miner
    * @param _payoutMultiplier is calculated in the proofOfWork function to 
    * allocate the additional miner tip added via the addToValuePool function
    */
    function pushValue(uint _apiId, uint _time, uint _payoutMultiplier) internal {
        Details[5] memory a = first_five;
        uint[5] memory _payout;
        for (uint i = 1;i <5;i++){
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
        devTransfer(owner(),(payoutTotal * devShare / 100));
        values[_apiId][_time] = a[2].value;
        minersbyvalue[_apiId][_time] = [a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner];
        emit Mine(msg.sender,[a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout);
        emit NewValue(_api,timeOfLastProof,a[2].value);
    }

    function getMedianMinerbyApiIdTimestamp(uint apiId, uint timestamp) public returns(address) {
        address[5] _miners = minersbyvalue[_apiId][_time];
        address _miner = miners[2];
        return _miner;
    }
}
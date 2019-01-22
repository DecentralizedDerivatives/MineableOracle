pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";

/**
 * @title Oracle 
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * Includes functions for users to read data from, tip the miners and for miners to submit
 * values and get paid out from the master ProofOfWorkToken contract
 */
contract Oracle{
    using SafeMath for uint256;
    /*Variables*/
    bytes32 public currentChallenge; //current challenge to be solved
    uint public devShare;//devShare of contracts
    uint public timeOfLastProof; // time of last challenge solved
    uint public count;//Number of miners who have mined this value so far
    uint256 public difficulty; // Difficulty of current block
    uint public timeTarget; //The time between blocks (mined Oracle values)
    uint[5] public payoutStructure;//The structure of the payout (how much uncles vs winner recieve)
    //does miners need to be mapped to the request id?
    mapping(bytes32 => mapping(address=>bool)) miners;//This is a boolean that tells you if a given challenge has been completed by a given miner

    //API on q info
    string public apiOnQ;
    uint public apiOnQPayout;
    uint public timeOnQ;

//*********************SAVING Unique requests Information***************************/
    //api to id- user sends in string api and the api gets an id
    mapping(string => bytes32) as apiId;// api string gets an id = to count of requests array so apiID[string] = requestsID.length
    //id to string api
    mapping(bytes32 => string) as api;//get the api string by looping through the bytes32(standardAPIIds) array so api[1] = 'btc/usd'
    bytes32[] public apiIds;
    mapping(bytes32 => uint) public apiIdsIndex;


    //********** save each API's info in it's own struct as a timeseries*************/
    //*************payout pool only at API level*************************************/
    //**************will not work with sorting for median************************/
    //apiId to info for the api
/*    mapping(bytes32 => APIReqInfo) public APItimeseries;
    struct APIReqInfo {
        uint[] timestamp;
        uint[] values;
        mapping(uint => uint) timestampIndex;//timestamp to index
    }
    //apiID to add to payoutpool
    mapping(bytes32 => uint) public APIpayoutPool;
    mapping(address => bytes32) public sender;
*/
    //mapping apiId(one) to requestID(many)
    mapping(bytes32 => bytes32) public request; 
    bytes32[] public requestsID;//use requestsID length to loop through apiRequest and get string
    mapping(bytes32 => uint) public requestsIDIndex; 
    mapping(bytes32 => uint) public requestTimestamp;
    uint[] public timestampRequested;//used to iterate through requestsDetails
    mapping(bytes32 => uint) public timestampReqIndex;
    //mapping requestID to timestamp to requestInfo struct(why was the timestamp mapped to the block number on the original contract?)
    mapping(bytes32 => RequestInfo)) public requestDetails; //timestamp requested in unix time will be that which corresponds to the block timestamp requested
    
    struct RequestInfo {   
        uint payoutPool;//Mining Reward in PoWo tokens given to all miners per value + tips for this specific request
        uint timestampMined;//blocktimestamp
        uint value;
        address sender;
    }
//*********************SAVING requested Information***************************/    
uint[10] public valuesToValidate;//last 10 values array? how do limited arrays save data? 
//requestDetails[requestsID[requestIDIndex[count-10]]requestInfo.value, requestDetails[requestsID[requestIDIndex[count-9]]requestInfo.value...?

//requestID to 10 values array sent for validation
mapping(bytes32 =>valuesToValidate) public sentForValidation;
//how to map the array here 
/* [1,3,4,5,6,7,8,9,100]--array with last 10 values
/*index of the array mapped to the requestID(bytes32)?
[t,t,t,t,t,t,t,t,F]--array received from miners
index 10 what was the api and timestmap */
    Details[5] first_five;
    struct Details {
        uint value;
        address miner;
        bool[10] validated;//i still need an array to validate, if False is received(use index to exclude or remove data)
    }
    //requestID to miners
    mapping(bytes32 => address[5]) minersbyvalue;//This maps the requestID to the 5 miners who mined that value
    //apiID=>timestampIndex=> minersby value????????????
    mapping(bytes32 => mapping(uint=> address[5])) minersbyvalue;
    //if validated array contains a false send to proof of stake voting
    //miners and anyone can stake their tokens to mine and 
    //vote on another contract. so Validated[any one false value] triggers
    //PoS. Hence, the index for the false value has to map to the api and timestamp
    //and that has to be included on the miner challenge info




    /*Events*/
    event Mine(address sender,address[5] _miners, uint[5] _values);//Emits upon a succesful value mine, indicates the msg.sender, 5 miners included in block, and the mined value
    event NewValue(string _api,uint _time, uint _value);//Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event PoolPayout(address sender, string _api, uint _timestamp, address[5] _miners, uint[5] _values);//Emits when a pool is paid out, who is included and the amount(money collected from reads)
    event ValueAddedToPool(address sender,string _api, uint _value,uint _time);//Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event DataRetrieved(address _sender, string _api, uint _value);//Emits when someone retireves data, this shows the msg.sender and the value retrieved
    event DataRequested(address _sender, string _api, bytes32 _requestID, uint _timestamp, uint _payoutPool);//Emits when someone retireves data, this shows the msg.sender, the party who gets the read, and the timestamp requested
    event NonceSubmitted(address _miner, string _nonce, uint _value);//Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event NewAPIonQinfo(string _api, uint _time, uint _payoutPool); //Emits when a new API is moved to the top of the mining queue
    
    /*Constructors*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master ProofOfWorkToken.address
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    * @param _devShare for dev
    */
    constructor(address _master,uint _timeTarget,uint[5] _payoutStructure, uint _devShare) public{
        require(_timeTarget > 60);
        timeOfLastProof = now - now  % _timeTarget;
        timeCreated = now;
        devShare = _devShare;
        timeTarget = _timeTarget;     
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
    function proofOfWork(string nonce, uint value) external returns (uint256,uint256) {
//add the api with largest payoutPool, timestamp, [values to valdidate]
         
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

        require(uint(n) % difficulty == 0 && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a value  
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        uint _payoutMultiplier = 1;
        emit NonceSubmitted(msg.sender,nonce,apiOnQ,value,validated[10];///how does this work added the api and them havign to validate/true/false previous 10 values
        if(count == 5) { 
            if (now - timeOfLastProof < (timeTarget *60)/100){
                difficulty++;
            }
            else if (now - timeOfLastProof > timeTarget && difficulty > 1){
                difficulty--;
            }
            
            uint i = (now - (now % timeTarget) - timeOfLastProof) / timeTarget;
            timeOfLastProof = now - (now % timeTarget);
            uint valuePool;
            while(i > 0){
                valuePool += payoutPool[timeOfLastProof - (i - 1) * timeTarget];
                i = i - 1;
            }
            if(valuePool >= payoutTotal) {
                _payoutMultiplier = (valuePool + payoutTotal) / payoutTotal; //solidity should always round down
                payoutPool[timeOfLastProof] = valuePool % payoutTotal;
            }
            else{
                payoutPool[timeOfLastProof] = valuePool;
            }
            pushValue(timeOfLastProof,apiOnQ,_payoutMultiplier);
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
    function addToValuePool(string _api, uint _tip, uint _timestamp) public {
        require(callTransfer(msg.sender,_tip));
        uint _time;
        if(_timestamp == 0){
            _time = timeOfLastProof + timeTarget;
        }
        else{
            _time = _timestamp - (_timestamp % timeTarget);
        }
        requestInfo memory requestDetails[requestID];
        requestInfo storage request = requestDetails[]
        payoutPool[_api][_time] = payoutPool[_api][_time].add(_tip);
        if (payoutPool[_api][_time] > apiMiningQPayout) {
            miningAPI[api]
        } 
        emit ValueAddedToPool(msg.sender,_api,_tip,_time);
        updateAPIonQ(_api,  _timestamp);
    }

    /**
    @dev use this function to update APIonQ via requestData or addToValuePool
    @param _api being requested
    @param _timestamp
    */
    function updateAPIonQ (string _api, uint _timestamp) internal {
        _payout = getValuePoolAt(string _api,uint _timestamp);
        if (_payout > apiOnQPayout ) {
            //update apiOnQ, apiOnPayout, and TimeOnQ
            apiOnQ = _api;
            apiOnQPayout = _payout;
            timeOnQ = _timestamp;
            emit NewAPIonQinfo(apiOnQ, timeOnQ, apiOnQPayout);
        } else {
            emit APIonQinfo(apiOnQ, timeOnQ, apiOnQPayout);
        }
    }

//I need this for the miners
    /**
    @dev Getter function for the information of the API on queue for mining 
    @return api, timestamp, and payout
    */
    function getAPIonQinfo() public returns(string, uint, uint){
        return(apiOnQ, timeOnQ, apiOnQPayout); 
    }


    /**
    * @dev Retrieve payout from the data reads. It pays out the 5 miners.
    * @param _timestamp for which to retreive the payout from
    */
    function retrievePayoutPool(string _api, uint _timestamp) public {
        uint _payoutMultiplier = payoutPool[_api][_timestamp] / payoutTotal;
        require (_payoutMultiplier > 0 && values[_api][_timestamp] > 0);
        uint[5] memory _payout = [payoutStructure[4]*_payoutMultiplier,payoutStructure[3]*_payoutMultiplier,payoutStructure[2]*_payoutMultiplier,payoutStructure[1]*_payoutMultiplier,payoutStructure[0]*_payoutMultiplier];
        batchTransfer(minersbyvalue[_api][_timestamp], _payout,false);
        emit PoolPayout(msg.sender,_api,_timestamp,minersbyvalue[_api][_timestamp], _payout);
    }


    /**
    * @dev Request to retreive value from oracle based on timestamp
    * @param _api the api being requested for mining
    * @param _timestamp to retreive data/value from
    * @param _party who gets the tokens
    * @param _requestGas the minimum required fee to request data to be mined
    */
    function requestData(string _api, uint _timestamp, address _party, uint _requestGas) public{
        require(_requestGas>= 1 && callTransfer(msg.sender,_requestGas));
        uint _requestID=apiRequests.length;
        apiRequest[_api]=_requestID;
        apiRequests.push(_api);
        requestInfo storage request = requestsDetails[_requestID][_timestamp];
        request.payoutPool = request.payoutPool + _requestGas;
        //payoutPool[_api][_timestamp] = payoutPool[[_api][_timestamp] + _requestGas;
        //request[msg.sender][_api][_timestamp] = block.number;  //Don't care about msg.sender or block number...
        
        emit DataRequested(msg.sender,_api,_requestID,_timestamp, request.payoutPool);
        updateAPIonQ(_requestID,  _timestamp);
    }

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(string _api, uint _timestamp) public returns (uint) {
        require(isData(_timestamp));
        emit DataRetrieved(msg.sender,values[_api][_timestamp]);
        return values[_api][_timestamp];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified _timestamp 
    * @param _timestamp is the timestamp to look up miners for
    */
    function getMinersByValue(string _api, uint _timestamp) public view returns(address[5]){
        return minersbyvalue[_api][_timestamp];
    }

    /**
    * @dev Checks if a requests has already been submitted for a party
    * @param _timestamp is the timestampt to look up miners for
    * @param _party address used to check if a request has been made on their behalf 
    * @return block number (uint) for request
    */
    function getRequest(string _api, uint _timestamp, address _party) public view returns(uint){
        return request[_party][_api][_timestamp];
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
    function isData(string _api, uint _timestamp) public view returns(bool){
        return (values[_api][_timestamp] > 0);
    }

    /**
    * @dev Getter function for currentChallenge difficulty
    * @return current challenge and level of difficulty
    */
    function getVariables() external view returns(bytes32, uint){
        return (currentChallenge,difficulty);
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    */
    function getLastQuery() external returns(uint,bool){
        if(request[msg.sender][timeOfLastProof] == 0){
            requestData(timeOfLastProof,msg.sender);
            return (0,false);
        }
        else{
            return (retrieveData(timeOfLastProof),true);//get last api????????????????
        }
    }

    /**
    * @dev Getter function for the payoutPool total for the specified _timestamp
    * If the _timestamp is not specified(_timestamp=0) it will return the total payoutPool
    * for the _timestamp being mined
    * @param _timestamp to look up the total payoutPool value 
    * @return the value of the total payoutPool
    */
    function getValuePoolAt(string _api,uint _timestamp) external view returns(uint){
        if(_timestamp == 0){
            uint _time = timeOfLastProof.add(timeTarget);
            return payoutPool[_api][_time];
        }
        else{
            return payoutPool[_api][_timestamp];
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
    function pushValue(uint _time, string apiOnQ, uint _payoutMultiplier) internal {
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
        devTransfer(owner(),(payoutTotal * devShare / 100 ));
        values[apiOnQ][_time] = a[2].value;
        //maybe add to an array[10];
        minersbyvalue[_time] = [a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner];
        emit Mine(msg.sender,[a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout);
        emit NewValue(apiOnQ,timeOfLastProof,a[2].value);
    }
}

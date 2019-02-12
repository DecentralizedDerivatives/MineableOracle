pragma solidity ^0.5.0;

import "./libraries/SafeMath.sol";
import "./libraries/Utilities.sol";
import "./Disputable.sol";


/**
 * @title Oracle Token
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * Includes functions for users to read data from, tip the miners and for miners to submit
 * values and get paid out from the master ProofOfWorkToken contract
 * TODO: Check miners are staked when submitting POW and add tipping at API level. 
 */
contract Oracle is Disputable{
    using SafeMath for uint256;

    uint  constant public payoutTotal = 22e18;//Mining Reward in PoWo tokens given to all miners per value
    uint constant public timeTarget = 10 * 60; //The time between blocks (mined Oracle values)
    uint[5] public payoutStructure =  [1e18,5e18,10e18,5e18,1e18];//The structure of the payout (how much uncles vs winner recieve)
    uint constant public requestFee = 1;

    /*Variables*/
    bytes32 public currentChallenge; //current challenge to be solved
    uint public timeOfLastProof; // time of last challenge solved
    uint public count;//Number of miners who have mined this value so far
    uint256 public difficulty_level; // Difficulty of current block
    bytes32 public apiOnQ; //string of current api with highest PayoutPool
    uint public apiOnQPayout; //value of highest api/timestamp PayoutPool
    uint public miningApiId; //API being mined--updates with the ApiOnQ Id 
    mapping(uint => uint) public timeToApiId;//minedTimestamp to apiId
    uint[] public timestamps;
    uint private requests;
    //challenge to miner address to yes/no--where yes if they completed the channlenge
    mapping(bytes32 => mapping(address=>bool)) miners;//This is a boolean that tells you if a given challenge has been completed by a given miner
    

    Details[5] first_five;
    struct Details {
        uint value;
        address miner;
    }


    mapping(uint => uint) apiListIndexToId;
    uint[50] payoutPool;


    /*Events*/
    event Mine(address sender,address[5] _miners, uint _paid);//Emits upon a succesful value mine, indicates the msg.sender, 5 miners included in block, and the mined value
    event NewValue(uint _apiId, uint _time, uint _value);//Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event ValueAddedToPool(address sender, uint _apiId, uint _value);//Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event DataRequested(address _sender, bytes32 _api, uint _apiId);//Emits when someone retireves data, this shows the msg.sender, the party who gets the read, and the timestamp requested
    event NonceSubmitted(address _miner, string _nonce, uint _apiId, uint _value);//Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event NewAPIonQinfo(uint _apiId, bytes32 _apiOnQ, uint _apiOnQPayout); //emits when a the payout of another request is higher after adding to the payoutPool or submitting a request


    /*Constructor*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    */
    constructor() public{
        timeOfLastProof = now - now  % timeTarget;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty_level = 1;
        payoutPool[0] = 1;
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
        require(isStaked(msg.sender) && _apiId == miningApiId);
        bytes32 _solution = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        bytes32 n = sha256(abi.encodePacked(ripemd160(abi.encodePacked(_solution))));
        require(uint(n) % difficulty_level == 0 && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        API storage _api = apiDetails[_apiId];
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        uint _payoutMultiplier = 1;
        emit NonceSubmitted(msg.sender,nonce,_apiId,value);
        if(count == 5) { 
            uint _timediff = now - timeOfLastProof;
            if (int(_timediff - timeTarget)!= 0){
                difficulty_level = difficulty_level - _timediff/60;
            }
            timeOfLastProof = now - (now % timeTarget);
            if(_api.payout >= payoutTotal) {
                _payoutMultiplier = (_api.payout + payoutTotal) / payoutTotal; //solidity should always round down
                _api.payout = _api.payout % payoutTotal;
            }
            Details[5] memory a = first_five;
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
            uint _amount;
            uint _paid;
            for (i = 0;i <5;i++){
                _amount = payoutStructure[i]*_payoutMultiplier + _api.payout/5;
                doTransfer(address(this),a[i].miner,_amount);
                _paid += _amount;
            }
            _api.payout = 0;      
            total_supply += _paid;
            doTransfer(address(this),owner(),(payoutTotal * devShare / 100));
            _api.values[timeOfLastProof] = a[2].value;
            _api.minersbyvalue[timeOfLastProof ] = [a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner];
            emit Mine(msg.sender,[a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _paid);
            emit NewValue(_apiId,timeOfLastProof,a[2].value);
            _api.minedBlockNum[timeOfLastProof] = block.number;
            miningApiId = apiId[apiOnQ]; 
            timeToApiId[timeOfLastProof] = _apiId;
            timestamps.push(timeOfLastProof);
            count = 0;
            currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
            return (count,timeOfLastProof); 
            payoutPool[_api.index] = 0;
            _api.index = 0;
            uint _index;
            uint _max;
            (_max,_index) = Utilities.getMax(payoutPool);
            miningApiId = apiListIndexToId[_index];
            apiOnQ = apiDetails[miningApiId].apiHash;
            apiOnQPayout = _max;
            emit NewAPIonQinfo(miningApiId,apiOnQ,apiOnQPayout);
        }
    }

    /**
    @dev This contract uses this function to update APIonQ when requestData or addToValuePool are ran
    @param _apiId being requested
    */
    function updateAPIonQ (uint _apiId) internal {
        API storage _api = apiDetails[_apiId];
        uint _payout = _api.payout;
        if (_payout > apiOnQPayout ) {
            miningApiId = _apiId;
            apiOnQ = _api.apiHash;
            apiOnQPayout = _payout;
            emit NewAPIonQinfo(miningApiId,apiOnQ,apiOnQPayout);
        }
        if(_api.index == 0){
            uint _min;
            uint _index;
            (_min,_index) = Utilities.getMin(payoutPool);
            if(_payout > _min){
                payoutPool[_index] = _payout;
                apiListIndexToId[_index] = _apiId;
                _api.index = _index;
            }
        }
        else{
            payoutPool[_api.index] = _payout;
        }
    }
    /**
    * @dev Adds the _tip to the valuePool that pays the miners
    * @param _apiId the api Id the user want to add to the value pool.
    * @param _tip amount to add to value pool
    * It should be the time stamp the user wants to ensure gets mined. They can do that 
    * by adding a _tip to insentivize the miners to submit a value for the time stamp. 
    */
    function addToValuePool (uint _apiId, uint _tip) public {      
        doTransfer(msg.sender,address(this),_tip);
        API storage _api = apiDetails[_apiId];
        _api.payout = _api.payout.add(_tip);
        updateAPIonQ(_apiId);
        emit ValueAddedToPool(msg.sender,_apiId,_tip);
    }
    /**
    * @dev Request to retreive value from oracle based on timestamp
    * @param _sapi being requested be mined
    * @param _tip amount the requester is willing to pay to be get on queue. Miners
    * mine the apiOnQ, or the api with the highest payout pool
    */
    function requestData(string memory _sapi, uint _tip) public returns(uint _apiId){
        bytes memory tempEmptyStringTest = bytes(_sapi);
        require(tempEmptyStringTest.length > 0);
        bytes32 _apiHash;
        assembly {
            _apiHash := mload(add(_sapi, 32))
        }
        require(apiId[_apiHash] == 0 && _tip>= requestFee);
        doTransfer(msg.sender,address(this),_tip);
        requests++;
        uint _apiId=requests;
        apiDetails[_apiId] = API({
            api_string : _sapi, 
            apiHash: _apiHash,
            payout: _tip,
            index: 0
            });
        apiId[_apiHash] = _apiId;
        updateAPIonQ (_apiId);
        emit DataRequested(msg.sender,_apiHash,_apiId);
    }
    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _apiId being requested
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _apiId, uint _timestamp) public view returns (uint) {
        return apiDetails[_apiId].values[_timestamp];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified apiId/_timestamp 
    * @param _apiId to look up
    * @param _timestamp is the timestampt to look up miners for
    */
    function getMinersByValue(uint _apiId, uint _timestamp) public view returns(address[5] memory){
        return apiDetails[_apiId].minersbyvalue[_timestamp];
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
        return (apiDetails[_apiId].values[_timestamp] > 0);
    }

    /**
    * @dev Getter function for currentChallenge difficulty_level
    * @return current challenge, MiningApiID, level of difficulty_level
    */
    function getVariables() external view returns(bytes32, uint, uint,string memory){    
        return (currentChallenge,miningApiId,difficulty_level,apiDetails[miningApiId].api_string);
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    */
    function getLastQuery() external view returns(uint,bool){
        return (retrieveData(timeToApiId[timeOfLastProof], timeOfLastProof),true);
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
        return apiDetails[_apiId].apiHash;
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
    * @dev Getter function for the payoutPool total for the specified _apiId
    * @param _apiId to look up the total payoutPool value
    * @return the value of the total payoutPool
    */
    function getValuePoolAt(uint _apiId) external view returns(uint){
        return apiDetails[_apiId].payout;
    }
}
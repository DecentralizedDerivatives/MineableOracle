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

    /*Variables*/
    bytes32 public currentChallenge; //current challenge to be solved
    bytes32 public apiOnQ; //string of current api with highest PayoutPool
    uint public timeOfLastProof; // time of last challenge solved
    uint256 public difficulty_level; // Difficulty of current block
    uint public apiIdOnQ;
    uint public apiOnQPayout; //value of highest api/timestamp PayoutPool
    uint public miningApiId; //API being mined--updates with the ApiOnQ Id 
    uint private requests;
    uint private count;//Number of miners who have mined this value so far
    uint  constant public payoutTotal = 22e18;//Mining Reward in PoWo tokens given to all miners per value
    uint constant public timeTarget = 10 * 60; //The time between blocks (mined Oracle values)
    uint[5] payoutStructure =  [1e18,5e18,10e18,5e18,1e18];//The structure of the payout (how much uncles vs winner recieve)
    uint[50] public payoutPool;
    uint[] public timestamps;

    //challenge to miner address to yes/no--where yes if they completed the channlenge
    mapping(bytes32 => mapping(address=>bool)) public miners;//This is a boolean that tells you if a given challenge has been completed by a given miner
    mapping(uint => uint) public timeToApiId;//minedTimestamp to apiId 
    mapping(uint => uint) public payoutPoolIndexToApiId;

    Details[5] first_five;
    struct Details {
        uint value;
        address miner;
    }

    /*Events*/
    event Mine(uint timeOfLastProof,address sender,address[5] _miners, uint _paid);//Emits upon a succesful value mine, indicates the msg.sender, 5 miners included in block, and the mined value
    event NewValue(uint _apiId, uint _time, uint _value);//Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event ValueAddedToPool(address sender, uint _apiId, uint _value);//Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event DataRequested(address _sender,string _sapi, bytes32 _apiHash, uint _apiId);//Emits when someone retireves data, this shows the msg.sender, the party who gets the read, and the timestamp requested
    event NonceSubmitted(address _miner, string _nonce, uint _apiId, uint _value);//Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event NewAPIonQinfo(uint _apiId, string _sapi, bytes32 _apiOnQ, uint _apiOnQPayout); //emits when a the payout of another request is higher after adding to the payoutPool or submitting a request
    event NewChallenge(bytes32 _currentChallenge,uint _miningApiId,uint _difficulty_level,string _api);

    /*Constructor*/
    constructor() public{
        timeOfLastProof = now - now  % timeTarget;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty_level = 1;
    }

    function initStake() public{
        require(requests == 0);
        address payable[5] memory _initalMiners = [address(0xE037EC8EC9ec423826750853899394dE7F024fee),
        address(0xcdd8FA31AF8475574B8909F135d510579a8087d3),
        address(0xb9dD5AfD86547Df817DA2d0Fb89334A6F8eDd891),
        address(0x230570cD052f40E14C14a81038c6f3aa685d712B),
        address(0x3233afA02644CCd048587F8ba6e99b3C00A34DcC)];
        for(uint i=0;i<5;i++){
            updateValueAtNow(balances[_initalMiners[i]],1e18);
            stakers.push(_initalMiners[i]);
            staker[_initalMiners[i]] = StakeInfo({
                current_state: 1,
                startDate: now - (now % 86400),
                index:stakers.length-1
                });
            emit NewStake(_initalMiners[i]);
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
    function proofOfWork(string calldata nonce, uint _apiId, uint value) external{
        require(isStaked(msg.sender) && _apiId == miningApiId);
        bytes32 n = sha256(abi.encodePacked(ripemd160(abi.encodePacked(keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce))))));
        require(uint(n) % difficulty_level == 0 && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        emit NonceSubmitted(msg.sender,nonce,_apiId,value);
        if(count == 5) { 
            API storage _api = apiDetails[_apiId];
            uint[3] memory nums; //reusable number array -- _amount,_paid,payoutMultiplier
            if(int(difficulty_level) + int((timeTarget - (now - timeOfLastProof))/60) > 0){
                difficulty_level = uint(int(difficulty_level) + int((timeTarget -(now - timeOfLastProof))/60));
            }
            timeOfLastProof = now - (now % timeTarget);
            if(_api.payout >= payoutTotal) {
                nums[2] = (_api.payout + payoutTotal) / payoutTotal; //solidity should always round down
                _api.payout = _api.payout % payoutTotal;
            }
            else{
                nums[2] = 1;
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
            for (i = 0;i <5;i++){
                nums[1] = payoutStructure[i]*nums[2] + _api.payout/5;
                doTransfer(address(this),a[i].miner,nums[1]);
                nums[0] = nums[0] + nums[1];
            }
            emit Mine(timeOfLastProof,msg.sender,[a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner],nums[0]);
            _api.payout = 0;      
            total_supply += nums[0];
            doTransfer(address(this),owner(),(payoutTotal * 10 / 100));//The ten there is the devshare
            _api.values[timeOfLastProof] = a[2].value;
            _api.minersbyvalue[timeOfLastProof ] = [a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner];
            _api.minedBlockNum[timeOfLastProof] = block.number;
            miningApiId = apiId[apiOnQ]; 
            timeToApiId[timeOfLastProof] = _apiId;
            timestamps.push(timeOfLastProof);
            count = 0;
            payoutPool[_api.index] = 0;
            payoutPoolIndexToApiId[_api.index] = 0;
            _api.index = 0;
            if(miningApiId > 0){
                (nums[0],nums[1]) = Utilities.getSecond(payoutPool);
                if(nums[0] > 0){
                    apiIdOnQ = payoutPoolIndexToApiId[nums[1]];
                    apiOnQ = apiDetails[apiIdOnQ].apiHash;
                    apiOnQPayout = nums[0];
                }
                else{
                    apiIdOnQ = 0;
                }
                currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
                emit NewChallenge(currentChallenge,miningApiId,difficulty_level,apiDetails[miningApiId].apiString);       
            }
            emit NewValue(_apiId,timeOfLastProof,a[2].value);
        }
    }

    /**
    @dev This contract uses this function to update APIonQ when requestData or addToValuePool are ran
    @param _apiId being requested
    */
    function updateAPIonQ (uint _apiId) internal {
        API storage _api = apiDetails[_apiId];
        uint _payout = _api.payout;
        if (_payout > apiOnQPayout || apiIdOnQ == 0) {
            if(miningApiId == 0){
                miningApiId = _apiId;
                currentChallenge = keccak256(abi.encodePacked(_payout, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
                emit NewChallenge(currentChallenge,miningApiId,difficulty_level,apiDetails[miningApiId].apiString);
            }
            else{
                apiIdOnQ = _apiId;
                apiOnQ = _api.apiHash;
                apiOnQPayout = _payout;
                emit NewAPIonQinfo(_apiId,_api.apiString,apiOnQ,apiOnQPayout);
            }
        }
        if(_api.index == 0){
            uint _min;
            uint _index;
            (_min,_index) = Utilities.getMin(payoutPool);
            if(_payout > _min || _min == 0){
                payoutPool[_index] = _payout;
                payoutPoolIndexToApiId[_index] = _apiId;
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
        if(_tip > 0){
                doTransfer(msg.sender,address(this),_tip);
        }
        apiDetails[_apiId].payout = apiDetails[_apiId].payout.add(_tip);
        updateAPIonQ(_apiId);
        emit ValueAddedToPool(msg.sender,_apiId,_tip);
    }

   /**
    * @dev Request to retreive value from oracle based on timestamp
    * @param c_sapi being requested be mined
    * @param _tip amount the requester is willing to pay to be get on queue. Miners
    * mine the apiOnQ, or the api with the highest payout pool
    */
    function requestData(string calldata c_sapi, uint _tip) external returns(uint _apiId){
        string memory _sapi = c_sapi;
        bytes memory tempEmptyStringTest = bytes(_sapi);
        require(tempEmptyStringTest.length > 0);
        bytes32 _apiHash;
        assembly {
            _apiHash := mload(add(_sapi, 32))
        }
        if(apiId[_apiHash] > 0){
            addToValuePool(apiId[_apiHash],_tip);
        }
        else{
            if(_tip > 0){
                doTransfer(msg.sender,address(this),_tip);
            }
            requests++;
            _apiId=requests;
            apiDetails[_apiId] = API({
                apiString : _sapi, 
                apiHash: _apiHash,
                payout: _tip,
                index: 0
                });
            apiId[_apiHash] = _apiId;
            updateAPIonQ (_apiId);
            emit DataRequested(msg.sender,_sapi,_apiHash,_apiId);
        }
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
        return (currentChallenge,miningApiId,difficulty_level,apiDetails[miningApiId].apiString);
    }

    /**
    * @dev Getter function for api on queue
    * @return apionQ hash, id, payout, and api string
    */
    function getVariablesOnQ() external view returns(uint, uint,string memory){    
        return (apiIdOnQ,apiOnQPayout,apiDetails[apiIdOnQ].apiString);
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
    function getApiHash(uint _apiId) external view returns(bytes32){    
        return apiDetails[_apiId].apiHash;
    }

    /**
    * @dev Getter function for apiId based on api hash
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

    /**
    * @dev Getter function for the apiId for the specified payoutPool index
    * @param _payoutPoolIndexToApiId to look up the apiId
    * @return apiId
    */
    function getpayoutPoolIndexToApiId(uint _payoutPoolIndexToApiId) external view returns(uint){
        return payoutPoolIndexToApiId[_payoutPoolIndexToApiId];
    }

}

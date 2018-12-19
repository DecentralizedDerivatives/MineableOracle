pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./ProofOfWorkToken.sol";
//Instead of valuePool, can we balances of this address?

/**
 * @title Oracle Token
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 * Includes functions for users to read data from, tip the miners and for miners to submit
 * values and get paid out from the master ProofOfWorkToken contract
 */
contract OracleToken{
    using SafeMath for uint256;
    /*Variables*/
    bytes32 public currentChallenge; //current challenge to be solved
    uint public devShare;//devShare of contracts
    uint public timeOfLastProof; // time of last challenge solved
    uint public timeTarget; //The time between blocks (mined Oracle values)
    uint public timeCreated;//Time the contract was created
    uint public count;//Number of miners who have mined this value so far
    uint public readFee;//Fee in PoWO tokens to read a value
    uint public payoutTotal;//Mining Reward in PoWo tokens given to all miners per value
    uint public miningMultiplier;//This times payout total is the mining reward (it goes down each year)
    uint256 public difficulty; // Difficulty of current block
    uint[5] public payoutStructure;//The structure of the payout (how much uncles vs winner recieve)
    address public master;//Address of master ProofOfWorkToken that created this contract
    mapping(uint => uint) values;//This the time series of values stored by the contract where uint UNIX timestamp is mapped to value
    mapping(uint => address[5]) minersbyvalue;//This maps the UNIX timestamp to the 5 miners who mined that value
    mapping(uint => uint) payoutPool;//This is the payout pool for a given timestamp.  
    mapping(bytes32 => mapping(address=>bool)) miners;//This is a boolean that tells you if a given challenge has been completed by a given miner
    mapping(address => mapping(uint => uint)) request;//You must request a timestamp.  The value will be the block timestamp requested
    Details[5] first_five;
    struct Details {
        uint value;
        address miner;
    }

    /*Events*/
    event Mine(address sender,address[5] _miners, uint[5] _values);//Emits upon a succesful value mine, indicates the msg.sender, 5 miners included in block, and the mined value
    event NewValue(uint _time, uint _value);//Emits upon a successful Mine, indicates the blocktime at point of the mine and the value mined
    event PoolPayout(address sender,uint _timestamp, address[5] _miners, uint[5] _values);//Emits when a pool is paid out, who is included and the amount(money collected from reads)
    event ValueAddedToPool(address sender,uint _value,uint _time);//Emits upon someone adding value to a pool; msg.sender, amount added, and timestamp incentivized to be mined
    event MiningMultiplierChanged(uint _newMultiplier);//Each year, the mining reward decreases by 1/5 of the initial mining reward
    event DataRetrieved(address _sender, uint _value);//Emits when someone retireves data, this shows the msg.sender and the value retrieved
    event DataRequested(address _sender, address _party,uint _timestamp);//Emits when someone retireves data, this shows the msg.sender, the party who gets the read, and the timestamp requested
    event NonceSubmitted(address _miner, string _nonce, uint _value);//Emits upon each mine (5 total) and shows the miner, nonce, and value submitted

    /*Constructors*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master ProofOfWorkToken.address
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    constructor(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure, uint _devShare) public{
        require(_timeTarget > 60);
        timeOfLastProof = now - now  % _timeTarget;
        timeCreated = now;
        devShare = _devShare;
        master = _master;
        readFee = _readFee;
        timeTarget = _timeTarget;
        miningMultiplier = 1e18;
        payoutStructure = _payoutStructure;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
    }

    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master ProofOfWorkToken.address
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    function init(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure, uint _devShare) external {
        require (timeOfLastProof == 0 && _timeTarget > 60);
        timeOfLastProof = now - now  % _timeTarget;
        timeCreated = now;
        devShare = _devShare;
        master = _master;
        readFee = _readFee;
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
    function proofOfWork(string nonce, uint value) external returns (uint256,uint256) {
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

        require(uint(n) % difficulty == 0 && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        uint _payoutMultiplier = 1;
        emit NonceSubmitted(msg.sender,nonce,value);
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
            pushValue(timeOfLastProof,_payoutMultiplier);
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
    function addToValuePool(uint _tip, uint _timestamp) public {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.callTransfer(msg.sender,_tip));
        uint _time;
        if(_timestamp == 0){
            _time = timeOfLastProof + timeTarget;
        }
        else{
            _time = _timestamp - (_timestamp % timeTarget);
        }
        payoutPool[_time] = payoutPool[_time].add(_tip);
        emit ValueAddedToPool(msg.sender,_tip,_time);//_time instead of timestamp?
    }


    /**
    * @dev Retrieve payout from the data reads. It pays out the 5 miners.
    * @param _timestamp for which to retreive the payout from
    */
    function retrievePayoutPool(uint _timestamp) public {
        uint _payoutMultiplier = payoutPool[_timestamp] / payoutTotal;
        require (_payoutMultiplier > 0 && values[_timestamp] > 0);
        uint[5] memory _payout = [payoutStructure[4]*_payoutMultiplier,payoutStructure[3]*_payoutMultiplier,payoutStructure[2]*_payoutMultiplier,payoutStructure[1]*_payoutMultiplier,payoutStructure[0]*_payoutMultiplier];
        ProofOfWorkToken(master).batchTransfer(minersbyvalue[_timestamp], _payout,false);
        emit PoolPayout(msg.sender,_timestamp,minersbyvalue[_timestamp], _payout);
    }

    /**
    * @dev Changes the base miner payout by decreasiung by 1/5 for 5 years.
    * After 5 years all miners rewards come from data reads.
    * @return _newTotal after the payout is decreased
    */
    function updatePayoutTotal() public returns(uint _newTotal){
        uint yearsSince = (now - timeCreated) / (86400 * 365);
        if(yearsSince >=5){
            miningMultiplier = 0;
            emit MiningMultiplierChanged(miningMultiplier);
        }
        else if (yearsSince >=1){
            miningMultiplier = 1e18 * (5 - yearsSince)/5;
            emit MiningMultiplierChanged(miningMultiplier);
        }
        return miningMultiplier;
    }
    /**
    * @dev Request to retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @param _party who gets the tokens
    */
    function requestData(uint _timestamp, address _party) public{
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.callTransfer(msg.sender,readFee));
        if(_party == address(0)){
            _party = msg.sender;
        }
        request[_party][_timestamp] = block.number;
        emit DataRequested(msg.sender,_party,_timestamp);
    }
    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _timestamp) public returns (uint) {
        require(isData(_timestamp) && 0 < request[msg.sender][_timestamp] && request[msg.sender][_timestamp] < block.number);
        payoutPool[_timestamp] = payoutPool[_timestamp] + readFee;
        emit DataRetrieved(msg.sender,values[_timestamp]);
        return values[_timestamp];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified _timestamp 
    * @param _timestamp is the timestampt to look up miners for
    */
    function getMinersByValue(uint _timestamp) public view returns(address[5]){
        return minersbyvalue[_timestamp];
    }

    /**
    * @dev Gets the 5 miners who mined the value for the specified _timestamp 
    * @param _timestamp is the timestampt to look up miners for
    */
    function getRequest(uint _timestamp, address _party) public view returns(uint){
        return request[_party][_timestamp];
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
    function isData(uint _timestamp) public view returns(bool){
        return (values[_timestamp] > 0);
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
            return (retrieveData(timeOfLastProof),true);
        }
    }

    /**
    * @dev Getter function for the payoutPool total for the specified _timestamp
    * If the _timestamp is not specified(_timestamp=0) it will return the total payoutPool
    * for the _timestamp being mined
    * @param _timestamp to look up the total payoutPool value 
    * @return the value of the total payoutPool
    */
    function getValuePoolAt(uint _timestamp) external view returns(uint){
        if(_timestamp == 0){
            uint _time = timeOfLastProof.add(timeTarget);
            return payoutPool[_time];
        }
        else{
            return payoutPool[_timestamp];
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
    function pushValue(uint _time, uint _payoutMultiplier) internal {
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
            _payout[i] = payoutStructure[i]*_payoutMultiplier*miningMultiplier/1e18;
        }
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        _master.batchTransfer([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout,true);
        _master.devTransfer(_master.owner(),(payoutTotal * devShare / 100));
        values[_time] = a[2].value;
        minersbyvalue[_time] = [a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner];
        emit Mine(msg.sender,[a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout);
        emit NewValue(timeOfLastProof,a[2].value);
    }
}

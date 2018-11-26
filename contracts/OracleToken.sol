pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./ProofOfWorkToken.sol";
//Instead of valuePool, can we balances of this address?

/**
 * @title Oracle Token
 * @dev Turns a wallet into a mine for a specified ERC20 token
 */
contract OracleToken{

    using SafeMath for uint256;

    /*Variables*/
    bytes32 public currentChallenge;
    uint public timeOfLastProof; // time of last challenge solved
    uint public timeTarget;
    uint public count;
    uint public readFee;
    uint private payoutTotal;
    uint256 public difficulty; // Difficulty starts low
    uint[5] public payoutStructure;
    address public master;
    mapping(uint => uint) values;
    mapping(uint => address[5]) minersbyvalue;
    mapping(uint => uint) payoutPool;
    mapping(bytes32 => mapping(address=>bool)) miners;
    Details[5] first_five;

    struct Details {
        uint value;
        address miner;
    }

    /*Events*/
    event Mine(address[5] _miners, uint[5] _values);
    event NewValue(uint _time, uint _value);
    event PoolPayout(address[5] _miners, uint[5] _values);
    event ValueAddedToPool(uint _value,uint _time);

    /*Functions*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master oracleVote.address
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    constructor(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public{
        timeOfLastProof = now - now  % timeTarget;
        master = _master;
        readFee = _readFee;
        timeTarget = _timeTarget;
        payoutStructure = _payoutStructure;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
    }

    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master oracle address(OracleVote.address is ProofOfWorkToken)
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    function init(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) external {
        require (timeOfLastProof == 0);
        timeOfLastProof = now;
        master = _master;
        readFee = _readFee;
        timeTarget = _timeTarget;
        payoutStructure = _payoutStructure;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
    }

    /**
    * @dev Proof of work to be done for mining
    * @param nonce uint submitted by miner
    * @param value of api query
    * @return count of values sumbitted so far and the time of the last submission
    */
    function proofOfWork(string nonce, uint value) external returns (uint256,uint256) {
        bytes32 _solution = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        uint _rem = uint(_solution) % 3;
        bytes32 n;
        if(_rem == 3){
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
        uint _payoutMultiplier;
        if(count == 5) { 
            if (now - timeOfLastProof < timeTarget){
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
                i--;
            }
            if(valuePool >= payoutTotal) {
                _payoutMultiplier = (valuePool + payoutTotal) / payoutTotal; //solidity should always round down
                payoutPool[timeOfLastProof] = valuePool % payoutTotal;
                valuePool = valuePool - (payoutTotal*(_payoutMultiplier-1));
            }
            else{
                payoutPool[timeOfLastProof] = valuePool;
                _payoutMultiplier = 1;
            }
            pushValue(timeOfLastProof,_payoutMultiplier);
            count = 0;
            currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
        }
     emit NewValue(timeOfLastProof,value);
     return (count,timeOfLastProof); 
    }

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _timestamp) public returns (uint) {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(isData(_timestamp) && _master.callTransfer(msg.sender,readFee));
        payoutPool[_timestamp] = payoutPool[_timestamp] + readFee;
        return values[_timestamp];
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
    function getLastQuery() external returns(uint){
        return retrieveData(timeOfLastProof);
    }

    /**
    * @dev Adds the _tip to the valuePool that pays the miners
    * @param _tip amount to add to value pool
    * How to give tip for future price request??????
    */
    function addToValuePool(uint _tip, uint _timestamp) public {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.callTransfer(msg.sender,_tip));
        if(_timestamp == 0){
            payoutPool[timeOfLastProof.add(timeTarget)].add(_tip);
        }
        else{
            payoutPool[_timestamp % timeTarget].add(_tip);
        }
        emit ValueAddedToPool(_tip,_timestamp);
    }
    /**
    * @dev Retrieve money from the data reads
    * @param _timestamp amount to add to value pool
    * How to give tip for future price request??????
    */
    function retrievePayoutPool(uint _timestamp) public {
        uint _payoutMultiplier = payoutPool[_timestamp] / 22;
        require (_payoutMultiplier > 0 && now > _timestamp);
        uint[5] memory _payout = [payoutStructure[0]*_payoutMultiplier,payoutStructure[1]*_payoutMultiplier,payoutStructure[2]*_payoutMultiplier,payoutStructure[3]*_payoutMultiplier,payoutStructure[4]*_payoutMultiplier];
        ProofOfWorkToken(master).batchTransfer([minersbyvalue[_timestamp][0],minersbyvalue[_timestamp][1],minersbyvalue[_timestamp][2],minersbyvalue[_timestamp][3],minersbyvalue[_timestamp][4]], _payout,false);
        emit PoolPayout([minersbyvalue[_timestamp][0],minersbyvalue[_timestamp][1],minersbyvalue[_timestamp][2],minersbyvalue[_timestamp][3],minersbyvalue[_timestamp][4]], _payout);
    }

    /**
    * @dev This function rewards the first five miners that submit a value
    * through the proofOfWork function and sorts the value as it is received 
    * so that the median value is 
    * given the highest reward
    * @param _time is the time/date for the value being provided by the miner
    */
    function pushValue(uint _time, uint _payoutMultiplier) internal {
        Details[5] memory a = first_five;
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
        uint[5] memory _payout = [payoutStructure[0]*_payoutMultiplier,payoutStructure[1]*_payoutMultiplier,payoutStructure[2]*_payoutMultiplier,payoutStructure[3]*_payoutMultiplier,payoutStructure[4]*_payoutMultiplier];
        ProofOfWorkToken(master).batchTransfer([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout,false);
        values[_time] = a[2].value;
        minersbyvalue[_time] = [a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner];
        emit Mine([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], _payout);
    }
}

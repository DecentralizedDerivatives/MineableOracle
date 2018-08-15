pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./ProofOfWorkToken.sol";
/**
 * @title Mineable Token
 * @dev Turns a wallet into a mine for a specified ERC20 token
 */
contract OracleToken{

    using SafeMath for uint256;

    /*Variables*/
    bytes32 public currentChallenge;
    uint public timeOfLastProof; // time of last challenge solved
    uint256 public difficulty = 1; // Difficulty starts low
    uint public timeTarget;
    uint count;
    string public API;
    uint public readFee;
    address public master;
    uint[5] public payoutStructure;
    uint public  payoutMultiplier;
    mapping(uint => uint) values;
    Details[5] first_five;
    uint public valuePool;
    struct Details {
        uint value;
        address miner;
    }
 

    /*Events*/
    event Mine(address indexed to,uint _time, uint value);
    event NewValue(address _miner, uint _value);

    /*Functions*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _api is the oracle api
    * @param _master is the master oracle address
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    function init(string _api,address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) external {
        require (timeOfLastProof == 0);
        timeOfLastProof = now;
        API = _api;
        master = _master;
        readFee = _readFee;
        timeTarget = _timeTarget;
        payoutStructure = _payoutStructure;
    }

    /**
    * @dev Getter function for currentChallenge difficulty
    */
    function getVariables() public constant returns(bytes32, uint){
        return (currentChallenge,difficulty);
    }

    /**
    * @dev Proof of work to be done for mining
    * @param nonce uint submitted by miner
    * @param value rewarded
    * @return count of values sumbitted so far and the time of the last submission
    */
    function proofOfWork(string nonce, uint value) external returns (uint256,uint256) {
        bytes32 n = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        require(uint(n) % difficulty == 0 && value > 0); //can we say > 0? I like it forces them to enter a valueS  
        count++;
        first_five[count-1] = Details({
            value: value,
            miner: msg.sender
        }); 
        emit NewValue(msg.sender,value);
        if(count == 5) {
            if (now - timeOfLastProof< timeTarget){
                difficulty++;
            }
            else if (now - timeOfLastProof > timeTarget){
                difficulty--;
            }
            timeOfLastProof = now - (now % timeTarget);//should it be like this? So 10 minute intervals?;
            pushValue(timeOfLastProof);
            if(valuePool > 44) {
                valuePool = valuePool.sub(22);
                payoutMultiplier = valuePool / 22; //solidity should always round down
            }
            else{
                payoutMultiplier = 1;
            }
            emit Mine(msg.sender,timeOfLastProof, value); // execute an event reflecting the change
            count = 0;
            currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
        }
        return (count,timeOfLastProof);
    }

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _timestamp) public returns (uint) {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.transfer(address(master),readFee));
        valuePool.add(readFee);
        return values[_timestamp];
    }

    /**
    * @dev Checks if a value exists for the timestamp provided
    * @param _timestamp to retreive data/value from
    * @return true if the value exists/is greater than zero
    */
    function isData(uint _timestamp) external view returns(bool){
        return (values[_timestamp] > 0);
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    */
    function getLastQuery() external returns(uint){
        return retrieveData(timeOfLastProof);
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    */
    function addToValuePool(uint _tip) public {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.transfer(address(master),_tip));
    }

    /**
    * @dev This fucntion sorts values as they come in so that the
    * median can be identified later.
    */
    function insertionSort(Details[5] storage a)internal {
       for (uint i = 1;i < a.length;i++){
        uint temp = a[i].value;
        address temp2 = a[i].miner;
        uint j;
        for (j = i -1; j >= 0 && temp < a[j].value; j--)
            a[j+1].value = a[j].value;
            a[j+1].miner = a[j].miner;
       }
            a[j+1].value = temp;
            a[j+1].miner= temp2;
    }

    /**
    * @dev This fucntion rewards the first five miners that submit a value
    */
    function pushValue(uint _time) internal {
        insertionSort(first_five);
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        _master.iTransfer(first_five[2].miner, (payoutMultiplier.mul(payoutStructure[2]))); // reward to winner grows over time
        _master.iTransfer(first_five[1].miner, payoutMultiplier.mul(payoutStructure[1])); // reward to winner grows over time
        _master.iTransfer(first_five[3].miner, payoutMultiplier.mul(payoutStructure[3])); // reward to winner grows over time
        _master.iTransfer(first_five[0].miner, payoutMultiplier.mul(payoutStructure[0])); // reward to winner grows over time
        _master.iTransfer(first_five[4].miner, payoutMultiplier.mul(payoutStructure[4])); // reward to winner grows over time
        values[_time] = first_five[2].value;
    }



    
}

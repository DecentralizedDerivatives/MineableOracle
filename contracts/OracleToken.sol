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
    uint256 public difficulty; // Difficulty starts low
    uint public timeTarget;
    uint count;
    uint public readFee;
    address public master;
    uint[5] public payoutStructure;
    uint public  payoutMultiplier;
    mapping(uint => uint) values;
    mapping(bytes32 => mapping(address=>bool)) miners;
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
    * @param _master is the master oracle address? POWT?
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    constructor(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public{
        timeOfLastProof = now;
        master = _master;
        readFee = _readFee;
        timeTarget = _timeTarget;
        payoutStructure = _payoutStructure;
        currentChallenge = keccak256(abi.encodePacked(0,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
    }
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master oracle address? POWT?
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
        currentChallenge = keccak256(abi.encodePacked(0,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
    }

    /**
    * @dev Getter function for currentChallenge difficulty
    */
    function getVariables() external view returns(bytes32, uint){
        return (currentChallenge,difficulty);
    }

    /**
    * @dev Proof of work to be done for mining
    * @param nonce uint submitted by miner
    * @param value of api query?
    * @return count of values sumbitted so far and the time of the last submission
    */
    function proofOfWork(string nonce, uint value) external returns (uint256,uint256) {
        bytes32 n = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        require(uint(n) % difficulty == 0 && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        count++;
        first_five[count - 1].value = value;
        first_five[count - 1].miner = msg.sender;
        miners[currentChallenge][msg.sender] = true;
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
                valuePool = valuePool -22;
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

    function calculatePayoutStructure() internal view returns (uint[5]){
        uint[5] memory arr;
        for (uint i =0;i<payoutStructure.length;i++) {
            arr[i] = payoutStructure[i] * payoutMultiplier;
        }
        return arr;
    }


    /**
    * @dev This fucntion rewards the first five miners that submit a value
    * @param _time is the time/date for the value being provided by the miner
    */

    function pushValue(uint _time) internal {
        Details[5] memory a = first_five;
        for (uint i = 1;i < a.length;i++){
            uint temp = a[i].value;
            address temp2 = a[i].miner;
            uint j = i;
            while(j > 0 && temp < a[j-1].value){
                a[j].value = a[j-1].value;
                a[j].miner = a[j-1].miner;   
                j--;
            }
       }
        a[j].value = temp;
        a[j].miner= temp2;

        ProofOfWorkToken(master).batchTransfer([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], calculatePayoutStructure());
        values[_time] = a[2].value;
    }
}

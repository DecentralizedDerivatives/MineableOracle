pragma solidity ^0.4.21;


import "./Token.sol";
/**
 * @title Mineable Token
 *
 * @dev Turns a wallet into a mine for a specified ERC20 token
 */
contract OracleToken is Token {

    
    /*Variables*/

    bytes32 public currentChallenge;
    uint public timeOfLastProof; // time of last challenge solved
    uint256 public difficulty = 1; // Difficulty starts low
    uint count;
    address owner;
    string public oracleName;
    mapping(uint => uint) values;
    Details[5] first_five;
    struct Details {
        uint value;
        address miner;
    }
 

    /*Events*/
    event Mine(address indexed to,uint _time, uint value);
    event NewValue(address _miner, uint _value);

    /*Functions*/
    /**
     * @dev Constructor that sets the passed value as the token to be mineable.

     */
    constructor() public{
        timeOfLastProof = now;
        owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
   }

   function getVariables() public constant returns(bytes32, uint){
    return (currentChallenge,difficulty);
   }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public{
    require(newOwner != address(0));
    owner = newOwner;
  }

    /**
     * @dev Change the difficulty
     * @param _difficulty uint256 difficulty to be set
     */
    function setDifficulty(uint256 _difficulty) onlyOwner public{
        difficulty = _difficulty;
    }
    /**
     * @dev Proof of work to be done for mining
     * @param nonce uint
     * @return uint The amount rewarded
     */

    function proofOfWork(string nonce, uint value) returns (uint256,uint256) {
        bytes32 n = sha3(currentChallenge,msg.sender,nonce); // generate random hash based on input
        if (uint(n) % difficulty !=0) revert();
        timeOfLastProof = now - (now % 60);
        count++;
        if (count<=5) {
           first_five[count-1] = Details({
                value: value,
                miner: msg.sender
            });  
           emit NewValue(msg.sender,value);
        } 
        if(count == 5) {
            pushValue(timeOfLastProof);
            emit Mine(msg.sender,timeOfLastProof, value); // execute an event reflecting the change
            count = 0;
        }
        else {
        currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number - 1)); // Save hash for next proof
        }
        return (count,timeOfLastProof);
    }

    function pushValue(uint _time) internal {
        quickSort(first_five,0,4);
        iTransfer(first_five[2].miner, 10); // reward to winner grows over time
        iTransfer(first_five[1].miner, 5); // reward to winner grows over time
        iTransfer(first_five[3].miner, 5); // reward to winner grows over time
        iTransfer(first_five[0].miner, 1); // reward to winner grows over time
        iTransfer(first_five[4].miner, 1); // reward to winner grows over time
        values[_time] = first_five[2].value;
    }

    function retrieveData(uint _timestamp) public constant returns (uint) {
        return values[_timestamp];
    }


    function testAdd(uint _timestamp, uint _value) public{
      values[_timestamp] = _value;
    }

     function quickSort(Details[5] storage arr, uint left, uint right) internal {
        uint i = left;
        uint j = right;
        uint pivot = arr[left + (right - left) / 2].value;
        while (i <= j) {
            while (arr[i].value < pivot) i++;
            while (pivot < arr[j].value) j--;
            if (i <= j) {
                (arr[i].value, arr[j].value) = (arr[j].value, arr[i].value);
                (arr[i].miner, arr[j].miner) = (arr[j].miner, arr[i].miner);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }


    
}
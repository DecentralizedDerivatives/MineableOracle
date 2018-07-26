pragma solidity ^0.4.21;


import "./Token.sol";
import "./ProofOfWorkToken.sol"
/**
 * @title Mineable Token
 *
 * @dev Turns a wallet into a mine for a specified ERC20 token
 */
contract OracleToken{
    /*Variables*/

    bytes32 public currentChallenge;
    uint public timeOfLastProof; // time of last challenge solved
    uint256 public difficulty = 1; // Difficulty starts low
    uint count;
    string public API;
    ProofOfWorkToken master;
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
    function init(string _api,address _master) internal {
        timeOfLastProof = now;
        API = _api;
        master = ProofOfWorkToken(_master);
    }


   function getVariables() public constant returns(bytes32, uint){
    return (currentChallenge,difficulty);
   }

    /**
     * @dev Proof of work to be done for mining
     * @param nonce uint
     * @return uint The amount rewarded
     */

    function proofOfWork(string nonce, uint value) returns (uint256,uint256) {
        bytes32 n = sha3(currentChallenge,msg.sender,nonce); // generate random hash based on input
        require(uint(n) % difficulty == 0);
        timeOfLastProof = now - (now % 60);
        count++;
        first_five[count-1] = Details({
            value: value,
            miner: msg.sender
        });  
        emit NewValue(msg.sender,value);
        if(count == 5) {
            pushValue(timeOfLastProof);
            emit Mine(msg.sender,timeOfLastProof, value); // execute an event reflecting the change
            count = 0;
            currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number - 1)); // Save hash for next proof
        }
        return (count,timeOfLastProof);
    }

    function pushValue(uint _time) internal {
        quickSort(first_five,0,4);
        master.iTransfer(first_five[2].miner, 10); // reward to winner grows over time
        master.iTransfer(first_five[1].miner, 5); // reward to winner grows over time
        master.iTransfer(first_five[3].miner, 5); // reward to winner grows over time
        master.iTransfer(first_five[0].miner, 1); // reward to winner grows over time
        master.iTransfer(first_five[4].miner, 1); // reward to winner grows over time
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
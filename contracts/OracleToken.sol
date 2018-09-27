pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./ProofOfWorkToken.sol";
//Instead of valuePool, can we balances of this address?

/**
 * @title Mineable Token
 * @dev Turns a wallet into a mine for a specified ERC20 token
 */
contract OracleToken{

    using SafeMath for uint256;

    /*Variables*/
    bytes32 public currentChallenge;
    uint public valuePool;
    uint public timeOfLastProof; // time of last challenge solved
    uint public timeTarget;
    uint public count;
    uint public readFee;
    uint private payoutTotal;
    uint public  payoutMultiplier;
    uint256 public difficulty; // Difficulty starts low
    uint[5] public payoutStructure;
    address public master;
    mapping(uint => uint) values;
    mapping(bytes32 => mapping(address=>bool)) miners;
    Details[5] first_five;

    struct Details {
        uint value;
        address miner;
    }
 
    struct TipInfo {
        uint tip;
        address tipper;
    }
    mapping(uint => TipInfo) public tipTime;//maps the tipTime to the array in the struct with all the tips from everyone
    uint[] public tipTimes;
    //mapping (uint => uint) public tipTimesIndex;//may not need index if tipTimes is sorted


    /*Events*/
    event Mine(address indexed to,uint _time, uint _value);
    event NewValue(address _miner, uint _value);
    event Print(uint _stuff,uint _more);
    event Print2(address[5] _miners,uint[5] _payoutStructure);
    event Print3(address victim);

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
        payoutMultiplier = 1;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
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
        payoutMultiplier = 1;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
    }

    /**
    * @dev Getter function for currentChallenge difficulty
    * @return current challenge and level of difficulty
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
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        emit NewValue(msg.sender,value);
        if(count == 5) { 
            if (now - timeOfLastProof< timeTarget){
                difficulty++;
            }
            else if (now - timeOfLastProof > timeTarget && difficulty > 1){
                difficulty--;
            }
            timeOfLastProof = now - (now % timeTarget);//should it be like this? So 10 minute intervals?;
            uint _dayStamp = now - (now % 86400);    
            if (isTipDate(_dayStamp)== true) {
                valuePool = valuePool.add(getTipInfo(_dayStamp));
            } 
            emit Print(payoutTotal,valuePool);
            if(valuePool >= payoutTotal) {
                payoutMultiplier = (valuePool + payoutTotal) / payoutTotal; //solidity should always round down
                valuePool = valuePool - (payoutTotal*(payoutMultiplier-1));
            }
            else{
                payoutMultiplier = 1;
            }
            pushValue(timeOfLastProof);
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
        require(isData(_timestamp) && _master.callTransfer(msg.sender,readFee));
        valuePool = valuePool.add(readFee);
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
    function addToValuePool(uint _tip) public {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.callTransfer(msg.sender,_tip));
        valuePool = valuePool.add(_tip);
    }

    /**
    * @dev This function rewards the first five miners that submit a value
    * through the proofOfWork function and sorts the value as it is received 
    * so that the median value is 
    * given the highest reward
    * @param _time is the time/date for the value being provided by the miner
    */
    function pushValue(uint _time) internal {
        Details[5] memory a = first_five;
        emit Print2([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner],payoutStructure);
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
        emit Print(payoutStructure[0],payoutMultiplier);
        ProofOfWorkToken(master).batchTransfer([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], [payoutStructure[0]*payoutMultiplier,payoutStructure[1]*payoutMultiplier,payoutStructure[2]*payoutMultiplier,payoutStructure[3]*payoutMultiplier,payoutStructure[4]*payoutMultiplier]);
        values[_time] = a[2].value;
        emit Mine(msg.sender,_time,a[2].value); // execute an event reflecting the change
    }


    /**
    *@dev getter function to get all tipTimes
    */
    function getTipTimes() view public returns (uint[]){
        return tipTimes;
    }

    function isTipDate(uint _timestamp) public view returns(bool){
        return (tipTime[_timestamp].tip > 0);
    }
    /**
    *@dev Gets tip amount for timestamp
    *@param _timestamp to view the tip amount
    */
    function getTipInfo(uint _timestamp) public constant returns(uint){
        return (tipTime[_timestamp].tip);
    }

    function retreiveTipIfNoValue(uint _timestamp) public {
        require(_timestamp % 86400 == 0);//the date is a day
        uint _dayStamp = now - (now % 86400);
        //require( _dayStamp > _timestamp);
        require(isData(_timestamp)==false);
        TipInfo storage tips = tipTime[_timestamp];
        require(tips.tipper == msg.sender);
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        _master.callTransfer(msg.sender,tips.tip);
        tips.tip = 0;
    }
    /**
    * @dev Adds the _tip to the valuePool that pays the miners
    * @param _tip amount to add to value pool
    * @param _timestamp unix time to disburse the tip
    * How to give tip for future price request??????
    */
    function addTimeTip(uint _tip, uint _timestamp) public {
        require(_timestamp % 86400 == 0);//the date is a day
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.callTransfer(msg.sender,_tip));
        TipInfo storage tips = tipTime[_timestamp];
        tips.tip = tips.tip.add(_tip);
        tips.tipper = msg.sender;
        tipTimes.push(_timestamp);//how to sort this??? delete history??
   /*      //sorting latest date to earliest or high to low
        uint n = tipTimes.length;
        uint[] memory tipTimes = new uint[] (n);
        for (uint i = 1;i < tipTimes.length;i++){
            //where temp is the time for the current array spot/index
            uint temp = tipTimes[i];
            uint j = i ;
            //while the index j >0 and temp/time < time in previous spot
            // when i =1 it compares the time of arry[i=1=j] to array[j-1=0]
            //while the latest value is less than the previous value
            //sorting high to low
            while (j  > 0 && temp < tipTimes[j-1]){
                //if i=3 ot dpes all the following comparisons, this cuould get messy and expensive
                //i=3 3 compares {3,2}{2,1}{1,0}
                //i=2 2 compares {3,2}{2,1}
                //i= 1 compares {1,0}
                //replace the latest timevalue with the prevous time value
                //so as long as tipTime[j=1]=100 < tiTimes[j-1=0]=200
                //switch J with j-1, or set tipTime[1]=200
                tipTimes[j] = tipTimes[j-1];
                j--;//j=0 so loop stops
            }
            //this is only true when j=0 
            //at this point it sets the array[0]=to the temp value
            if (j<i) {
                tipTimes[j] = temp;
            }
        } */
    }

}

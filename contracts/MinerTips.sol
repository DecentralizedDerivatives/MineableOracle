 pragma solidity ^0.4.24; 

/* import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./ProofOfWorkToken.sol";  */
//Instead of valuePool, can we balances of this address?

/**
 * @title Tips
 * @dev Allows users to add tips for miners to ensure the is mined
 */
/* contract MinerTips{

    using SafeMath for uint256;

    /*Variables*/

/*  
    struct TipInfo {
        uint tip;//change to array but then how do i add the entire array
        address tipper;//change to array
        //mapping (uint => uint) tipperIndex;
    }
    mapping(uint => TipInfo) public tipTime;//maps the tipTime to the array in the struct with all the tips from everyone
    uint[] public tipTimes; */ 
    //mapping (uint => uint) public tipTimesIndex;//may not need index if tipTimes is sorted

    /**
    *@dev getter function to get all tipTimes
    */
/*     function getTipTimes() view public returns (uint[]){
        return tipTimes;
    }

    function isTipDate(uint _timestamp) public view returns(bool){
        return (tipTime[_timestamp].tip > 0);
    } */
    /**
    *@dev Gets tip amount for timestamp
    *@param _timestamp to view the tip amount
    */
 /*    function getTipInfo(uint _timestamp) public constant returns(uint){
        return (tipTime[_timestamp].tip);
    } */

 /*    function retreiveTipIfNoValue(uint _timestamp) public {
        require(_timestamp % 86400 == 0);//the date is a day
        //uint _dayStamp = now - (now % 86400);
        //require( _dayStamp > _timestamp);
        require(isData(_timestamp)==false);
        TipInfo storage tips = tipTime[_timestamp];
        require(tips.tipper == msg.sender);
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        _master.callTransfer(msg.sender,tips.tip);
        tips.tip = 0;
    } */
    /**
    * @dev Adds the _tip to the valuePool that pays the miners
    * @param _tip amount to add to value pool
    * @param _timestamp unix time to disburse the tip
    * How to give tip for future price request??????
    */
/*     function addTimeTip(uint _tip, uint _timestamp) public {
        require(_timestamp % 86400 == 0);//the date is a day
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.callTransfer(msg.sender,_tip));
        TipInfo storage tips = tipTime[_timestamp];
        tips.tip = tips.tip.add(_tip);
        tips.tipper = msg.sender;
        tipTimes.push(_timestamp); *///how to sort this??? delete history??
   /*   //sorting latest date to earliest or high to low
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
  //  }

            //uint _dayStamp = now - (now % 86400);    
            //if (isTipDate(_dayStamp)== true) {
            //    valuePool = valuePool.add(getTipInfo(_dayStamp));
            //} 
//}
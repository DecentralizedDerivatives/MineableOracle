pragma solidity ^0.5.0;

//Slightly modified SafeMath library - includes a min function
library Utilities{
  
  function getSecond(uint[50] memory data) internal pure returns(uint256 second,uint secIndex) {
            uint maximal = data[0];
            uint maxIndex;
            second = data[1];
            for(uint i=1;i < data.length;i++){
                if(data[i] > second) {
                    if(data[i] > maximal){
                      second = maximal;
                      secIndex = maxIndex;
                      maximal = data[i];
                      maxIndex = i;
                    }
                    else{
                      second = data[i];
                      secIndex = i;
                    }
                }
            }
  }

  /// @dev Returns the minimum value in an array.
  function getMin(uint[50] memory data) internal pure returns(uint256 minimal,uint minIndex) {
        minIndex = data.length - 1;
        minimal = data[minIndex];
        for(uint i = data.length - 1;i > 0;i--) {
            if(data[i] < minimal) {
                minimal = data[i];
                minIndex = i;
            }
        }
  }
}

pragma solidity ^0.4.24;

import './OracleToken.sol';

contract Reader{

	uint public value;

    /**
    @dev Getter function to get value for last mined _timestamp
    @param _otoken OracleToken Address
    */
	function getLastValue(address _otoken) public{
		OracleToken token = OracleToken(_otoken);
		value = token.getLastQuery();
	}
}
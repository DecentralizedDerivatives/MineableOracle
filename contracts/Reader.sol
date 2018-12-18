pragma solidity ^0.4.24;

import './OracleToken.sol';
/**
* @title Reader
* This contracts tests for authorized and unauthorized access to data
*/
contract Reader{

	uint public value;
	bool public ifRetrieve;

    /**
    @dev Getter function to get value for last mined _timestamp
    @param _otoken OracleToken Address
    */
	function getLastValue(address _otoken) public {
		OracleToken token = OracleToken(_otoken);
		(value,ifRetrieve) = token.getLastQuery();
	}
}
pragma solidity ^0.4.24;

import './Oracle.sol';
/**
* @title Reader
* This contracts tests for authorized and unauthorized access to data
*/
contract Reader{

	uint public value;
	bool public ifRetrieve;

    /**
    @dev Getter function to get value for last mined _timestamp
    @param _oracle_add OracleToken Address
    */
	function getLastValue(address _oracle_add) public {
		Oracle doracle = Oracle(_oracle_add);
		(value,ifRetrieve) = doracle.getLastQuery();
	}
}
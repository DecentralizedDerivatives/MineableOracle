pragma solidity ^0.4.24;

import './OracleToken.sol';

contract Reader{

	uint public value;

	function getLastValue(address _otoken) public{
		OracleToken token = OracleToken(_otoken);
		value = token.getLastQuery();
	}
}
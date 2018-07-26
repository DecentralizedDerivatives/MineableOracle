pragma solidity ^0.4.24;

//Swap interface- descriptions can be found in TokenToTokenSwap.sol
interface OracleToken_Interface {
  function init(string _api) external;
}

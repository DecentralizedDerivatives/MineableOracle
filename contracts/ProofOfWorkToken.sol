pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
import "./Token.sol";
import "./CloneFactory.sol";
import "./OracleToken.sol";
/**
* @title Proof of Work token
* This is the master token where you deploy new oracles from.  
* Each oracle gets the API value specified
*/
contract ProofOfWorkToken is Token, CloneFactory {

    using SafeMath for uint256;

    string public constant name = "Proof-of-Work Oracle Token";
    string public constant symbol = "POWO";
    uint8 public constant decimals = 18;

    /*Variables*/
    struct OracleDetails {
        string API;
        address location;
    }
    address public dud_Oracle;

    OracleDetails[] public oracle_list;
    mapping(address => uint) oracle_index;

    
    /*Events*/
    event Deployed(string _api,address _newOracle);
    event ChangeDudOracle(address newDudOracle);
    event Mined(address miner,uint reward);
    

    /*Functions*/
    constructor() public{
        oracle_list.push(OracleDetails({
            API: "",
            location: address(0)
        }));
    }


    /**
    * @dev Set oracle dudd address to clone
    * @param _dud_Oracle address to clone
    */  
    function setDudOracle(address _dud_Oracle) internal {
        dud_Oracle = _dud_Oracle;
        emit ChangeDudOracle(dud_Oracle);
    }

    /**
    * @dev Deployes a new oracle 
    * @param _api is the oracle api
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    * @return new oracle address
    */
    function deployNewOracle(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) internal returns(address){
        address new_oracle = createClone(dud_Oracle);
        OracleToken(new_oracle).init(_api,address(this),_readFee,_timeTarget,_payoutStructure);
        oracle_index[new_oracle] = oracle_list.length;
        oracle_list.length++;
        OracleDetails storage _current = oracle_list[oracle_list.length-1]; 
        _current.API = _api;
        _current.location = new_oracle;  
        emit Deployed(_api, new_oracle);
        return new_oracle;
    }

    /**
    * @dev Allows for a transfer of tokens to _to
    * @param _to The address to send tokens to
    * @param _amount The amount of tokens to send
    * @return true if transfer is successful
    */
function batchTransfer(address[] _miners, uint256[] _amount) external{
    require(oracle_index[msg.sender] > 0);
    for (uint i = 0; i < _miners.lengt; i++) {
        if (balances[address(this)] >= _amount[i]
        && _amount[i] > 0
        && balances[_miners[i]].add(_amount[i]) > balances[_miners[i]]) {
            doTransfer(address(this),miners[i],amount[i]);
            emit Mined(_miners[i], _amount[i]);
        }
    }
}

    /**
    * @dev Allows  to remove oracle that are no longer in use
    * @param _removed is the oracle address to remove
    */
    function removeOracle(address _removed) internal{        
        uint _index = oracle_index[_removed];
        require(_index > 0);
        uint _last_index = oracle_list.length.sub(1);
        OracleDetails storage _last = oracle_list[_last_index];
        oracle_list[_index] = _last;
        oracle_index[_last.location] = _index;
        oracle_list.length--;
        oracle_index[_removed] = 0;
    }

    /**
    * @dev Getter function that gets the oracle API
    * @param _oracle is the oracle address to look up
    * @return the API and oracle address
    */
    function getDetails(address _oracle) public view returns(string,address){
        OracleDetails storage _current = oracle_list[oracle_index[_oracle]];
        return(_current.API,_current.location);
    }

    function getindex(address _oracle) public view returns(uint){
        return(oracle_index[_oracle]);
    }

}

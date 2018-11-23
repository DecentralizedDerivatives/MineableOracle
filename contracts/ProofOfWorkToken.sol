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

    /*Variables*/
    string public constant name = "Proof-of-Work Oracle Token";
    string public constant symbol = "POWO";
    uint8 public constant decimals = 18;
    uint firstDeployedTime;
    uint firstWeekCount;
    uint lastDeployedTime;
    mapping(uint => bool) allowedWeekDeployment; 
    address public dud_Oracle;
    address public owner;
    OracleDetails[] public oracle_list;
    mapping(address => uint) oracle_index;

    struct OracleDetails {
        string API;
        address location;
    }

    /*Events*/
    event Deployed(string _api,address _newOracle);
    event ChangeDudOracle(address newDudOracle);
    event Mined(address miner,uint reward);
    
    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    constructor() public{
        owner = msg.sender;
        firstDeployedTime = now - (now % 86400);
        oracle_list.push(OracleDetails({
            API: "",
            location: address(0)
        }));
    }

    /**
    * @dev Deploys a new oracle 
    * @param _api is the oracle api
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    * @return new oracle address
    */
    function deployNewOracle(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public onlyOwner() {
        uint _calledTime = now - (now % 86400);
        bool _allowDeploy = allowedWeekDeployment[lastDeployedTime];
        require(firstWeekCount<=10 && _calledTime - firstDeployedTime <= 604800 || _calledTime >= (lastDeployedTime + 604800) && _allowDeploy == false) ;
            if (firstWeekCount <=10 && _calledTime - firstDeployedTime <= 604800){
                firstWeekCount++; 
                deployNewOracleHelper(_api, _readFee, _timeTarget, _payoutStructure);
            } else if (_calledTime >= (lastDeployedTime + 604800) && _allowDeploy == false) {
                lastDeployedTime = _calledTime;
                allowedWeekDeployment[_calledTime] = true;
                deployNewOracleHelper(_api, _readFee, _timeTarget, _payoutStructure);
        }
    }

    function deployNewOracleHelper(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) internal returns(address){
        //require(msg.sender = address(this)); //not sure if i need this
        address new_oracle = createClone(dud_Oracle);
        OracleToken(new_oracle).init(address(this),_readFee,_timeTarget,_payoutStructure);
        oracle_index[new_oracle] = oracle_list.length;
        oracle_list.length++;
        OracleDetails storage _current = oracle_list[oracle_list.length-1]; 
        _current.API = _api;
        _current.location = new_oracle; 
        emit Deployed(_api, new_oracle);
        return new_oracle; 
    }
    /**
    * @dev Allows for a transfer of tokens to _miners 
    * @param _miners The five addresses to send tokens to
    * @param _amount The amount of tokens to send to each address
    */
    function batchTransfer(address[5] _miners, uint256[5] _amount) external{
        require(oracle_index[msg.sender] > 0);
        for (uint i = 0; i < _miners.length; i++) {
            if (balanceOf(address(this)) >= _amount[i]
            && _amount[i] > 0
            && balanceOf(_miners[i]).add(_amount[i]) > balanceOf(_miners[i])) {
                doTransfer(address(this),_miners[i],_amount[i]);
                emit Mined(_miners[i], _amount[i]);
            }
        }
    }

    /**
    * @dev Allows the OracleToken.RetreiveData to transfer the fee paid to retreive
    * data back to this contract
    * @param _from address to transfer from
    * @param _amount to transfer
    * @return true after transfer 
    */
    function callTransfer(address _from,uint _amount) public returns(bool){
        require(oracle_index[msg.sender] > 0);
        doTransfer(_from,address(this), _amount);
        return true;
    }

   
    /**
    * @dev Set oracle dudd address to clone
    * @param _dud_Oracle address to clone
    * ///Brenda comment---move to constructor?//////
    */  
    function setDudOracle(address _dud_Oracle) public onlyOwner() {
        dud_Oracle = _dud_Oracle;
        emit ChangeDudOracle(dud_Oracle);
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

    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }
}

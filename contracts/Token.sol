pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";

/**
* @title Token
* This contracts contains the ERC20 token functions
*/
contract Token {

    using SafeMath for uint256;
  
    /*Variables*/
    uint public minimumStake;//stake required to become a miner and/or vote on disputes in oracle tokens
    uint public minimumStakeTime;
    uint public total_supply;
    address[] public stakers;
    mapping (address => uint) public balances;
    mapping(address => mapping (address => uint)) internal allowed;
    mapping(address => uint) public stakersIndex;
    mapping(address => StakeInfo) public staker;
    struct StakeInfo {
        uint current_state;//1=started, 2 = ended, 3= OnDispute
        uint startDate; //stake start date
        uint stakeAmt;
    }
       
    /*Events*/
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event NewStake(address _sender, uint _value);
    event StakeWithdrawn(address _sender, uint _value);
    event StakeExtended(address _sender, uint _startdate, uint _stakeAmt);

    /*Functions*/
    /**
    * @dev Constructor that sets the passed value as the token to be mineable.
    */
    constructor() public{
        total_supply = 10000 ether;
        balances[msg.sender] = total_supply;
        balances[address(this)]= (2**256) - 1 - total_supply;
        minimumStake= 1e18;
        minimumStakeTime = 15552000;
    }
    

    /**
    * @dev Allows for a transfer of tokens to _to
    * @param _to The address to send tokens to
    * @param _amount The amount of tokens to send
    * @return true if transfer is successful
    */
     function transfer(address _to, uint256 _amount) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /**
    * @notice Send _amount tokens to _to from _from on the condition it
    * is approved by _from
    * @param _from The address holding the tokens being transferred
    * @param _to The address of the recipient
    * @param _amount The amount of tokens to be transferred
    * @return True if the transfer was successful
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }


    /** 
    * @dev Completes POWO transfers by updating the balances
    * @param _from address to transfer from
    * @param _to addres to transfer to
    * @param _amount to transfer 
    */
    function doTransfer(address _from, address _to, uint _amount) internal {
        require(_amount > 0 && _to != 0);
        uint _stakeAmt = getStakeAmt(_from);
        require(balances[_from]-_stakeAmt >= _amount);//lock the stake amt so it can't be moved until unstaked
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

    /** 
    * @dev Completes dispute transfer by updating the balances
    * @param _from address to transfer from
    * @param _to addres to transfer to
    * @param _amount to transfer 
    */
    function disputeTransfer(address _from, address _to, uint _amount) internal {
        StakeInfo memory stakes = staker[_from];
        require(_amount > 0 && _to != 0);
        require(stakes.current_state == 3);//lock the stake amt so it can't be moved until unstaked
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
    /**
    * @dev This function approves a _spender an _amount of tokens to use
    * @param _spender address
    * @param _amount amount the spender is being approved for
    * @return true if spender appproved successfully
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        uint _stakeAmt = getStakeAmt(msg.sender);
        require(balances[msg.sender]-_stakeAmt >= _amount);//lock the stake amt so it can't be moved until unstaked
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    /**
    * @dev Gets balance of owner specified
    * @param _owner is the owner address used to look up the balance
    * @return Returns the balance associated with the passed in _owner
    */
    function balanceOf(address _owner) public constant returns (uint bal) { 
        return balances[_owner]; 
    }

    /**
    * @dev Getter function allows you to view the allowance left based on the _owner and _spender
    * @param _owner address
    * @param _spender address
    * @return Returns the remaining allowance of tokens granted to the _spender from the _owner
    */
    function allowance(address _owner, address _spender) public view returns (uint) {
       return allowed[_owner][_spender]; }

    /**
    *@dev Getter for the total_supply of token
    *@return total supply
    */
    function totalSupply() public view returns(uint){
        return total_supply;
    }


/*****************Staking Functions***************/

/**
* @dev This function allows users to stake 
* @param _deposit amout to stake
*/
    function depositStake(uint _deposit) public {
        require(_deposit >= minimumStake && balanceOf(msg.sender) >= _deposit);
        stakers.push(msg.sender);
        stakersIndex[msg.sender] = stakers.length-1;
        StakeInfo memory stakes = staker[msg.sender];
        stakes.current_state = 1;
        stakes.startDate = now - (now % 86400);
        stakes.stakeAmt= _deposit;
        emit NewStake(msg.sender, _deposit);
    }

    function withdrawStake() public {
        StakeInfo memory stakes = staker[msg.sender];
        uint _today = now - (now % 86400);
        require(_today - stakes.startDate >= minimumStakeTime && stakes.current_state == 1 && balanceOf(msg.sender) >= stakes.stakeAmt);
        stakes.current_state = 2;
        emit StakeWithdrawn(msg.sender, stakes.stakeAmt);
        stakes.stakeAmt = 0;
    }

    function extendStake() public {
        StakeInfo memory stakes = staker[msg.sender];
        uint _today = now - (now % 86400);
        require(_today - stakes.startDate >= minimumStakeTime && stakes.current_state == 2 && balanceOf(msg.sender) >= stakes.stakeAmt);
        stakes.startDate = now - (now % 86400);
        emit StakeExtended(msg.sender, stakes.startDate, stakes.stakeAmt);
    }

    function getStakeAmt(address _sender) public view returns(uint){
        StakeInfo memory stakes = staker[_sender];
        return stakes.stakeAmt;
    }


/*****************Staking Functions***************/    
}

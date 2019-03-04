pragma solidity ^0.5.0;

import "./libraries/SafeMath.sol";
/**
* @title Token
* This contracts contains the ERC20 token functions
*/
contract Token  {

    using SafeMath for uint256;

    /*Variables*/
    uint public total_supply;
    uint constant stakeAmt = 1000e18;
    address[] public stakers;
    mapping (address => Checkpoint[]) public balances;
    mapping(address => mapping (address => uint)) internal allowed;
    mapping(address => StakeInfo) public staker;
    struct StakeInfo {
        uint current_state;//1=started, 2=LockedForWithdraw 3= OnDispute
        uint startDate; //stake start date
        uint index;
    }
    struct  Checkpoint {
        uint128 fromBlock;// fromBlock is the block number that the value was generated from
        uint128 value;// value is the amount of tokens at a specific block number
    }
      
    /*Events*/
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event NewStake(address _sender);
    event StakeWithdrawn(address _sender);
    event StakeWithdrawRequested(address _sender);

    /*Functions*/
    /**
    * @dev Constructor that sets the passed value as the token to be mineable.
    */
    /**********************remove msg.sender balance for productions*****************/
    constructor() public{
        updateValueAtNow(balances[address(this)], 2**256-1 - 5000e18);
    }
    
    /**
    * @dev Gets balance of owner specified
    * @param _owner is the owner address used to look up the balance
    * @return Returns the balance associated with the passed in _owner
    */
    function balanceOf(address _owner) public view returns (uint bal) { 
        return balanceOfAt(_owner, block.number); 
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
    * @dev Queries the balance of _owner at a specific _blockNumber
    * @param _owner The address from which the balance will be retrieved
    * @param _blockNumber The block number when the balance is queried
    * @return The balance at _blockNumber
    */
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
                return 0;
        }
     else {
        return getValueAt(balances[_owner], _blockNumber);
     }
    }

    /**
    * @dev Getter for balance for owner on the specified _block number
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _block is the block number to search the balance on
    */
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint) {
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /**
    * @dev Updates balance for from and to on the current block number via doTransfer
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _value is the new balance
    */
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
        } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
        }
    }
    
    /** 
    * @dev Completes POWO transfers by updating the balances on the current block number
    * @param _from address to transfer from
    * @param _to addres to transfer to
    * @param _amount to transfer 
    */
    function doTransfer(address _from, address _to, uint _amount) internal {
        require(_amount > 0 && _to != address(0) && allowedToTrade(_from,_amount));
        uint previousBalance = balanceOfAt(_from, block.number);
        updateValueAtNow(balances[_from], previousBalance - _amount);
        previousBalance = balanceOfAt(_to, block.number);
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        updateValueAtNow(balances[_to], previousBalance + _amount);
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
        require(_amount > 0 && _to != address(0) && stakes.current_state == 3);
        uint previousBalance = balanceOfAt(_from, block.number);
        require(previousBalance >= _amount);
        updateValueAtNow(balances[_from], previousBalance - _amount);
        previousBalance = balanceOfAt(_to, block.number);
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        updateValueAtNow(balances[_to], previousBalance + _amount);
        emit Transfer(_from, _to, _amount);
    }

    /**
    * @dev This function approves a _spender an _amount of tokens to use
    * @param _spender address
    * @param _amount amount the spender is being approved for
    * @return true if spender appproved successfully
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        require(allowedToTrade(msg.sender,_amount));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    * @param _owner address
    * @param _spender address
    * @return Returns the remaining allowance of tokens granted to the _spender from the _owner
    */
    function allowance(address _owner, address _spender) public view returns (uint) {
       return allowed[_owner][_spender]; }

    /**
    * @dev Getter for the total_supply of oracle tokens
    * @return total supply
    */
    function totalSupply() public view returns (uint) {
       return total_supply;
    }


/*****************Staking Functions***************/

/**
* @dev This function allows users to stake 
*/
    function depositStake() external {
        require( balanceOf(msg.sender) >= stakeAmt);
        stakers.push(msg.sender);
        staker[msg.sender] = StakeInfo({
            current_state: 1,
            startDate: now - (now % 86400),
            index:stakers.length-1
            });
        emit NewStake(msg.sender);
    }

    function withdrawStake() external {
        StakeInfo storage stakes = staker[msg.sender];
        uint _today = now - (now % 86400);
        require(_today - stakes.startDate >= 7 days && stakes.current_state == 2);
        stakes.current_state = 0;
        emit StakeWithdrawn(msg.sender);
    }

    function requestWithdraw() external {
        StakeInfo storage stakes = staker[msg.sender];
        require(stakes.current_state == 1);
        stakes.current_state = 2;
        stakes.startDate = now -(now % 86400);
        uint _index = stakes.index;
        uint _lastIndex = stakers.length - 1;
        address _lastStaker = stakers[_lastIndex];
        stakers[_index] = _lastStaker;
        staker[_lastStaker].index = _index;
        stakers.length--;
        emit StakeWithdrawRequested(msg.sender);
    }

    function allowedToTrade(address _user,uint _amount) public view returns(bool){
        StakeInfo memory stakes = staker[_user];
        if(stakes.current_state >0){
            if(balanceOf(_user).sub(stakeAmt).sub(_amount) > 0){
                return true;
            }
        }
        else if(balanceOf(_user).sub(_amount) > 0){
                return true;
        }
        return false;
    }

    function isStaked(address _staker) public view returns(bool){
        return (staker[_staker].current_state == 1);
    }

    function getStakersCount() external view returns(uint){
        return stakers.length;
    }

    function getStakerInfo(address _staker) public view returns(uint,uint,uint){
        return (staker[_staker].current_state,staker[_staker].startDate,staker[_staker].index);
    }
}

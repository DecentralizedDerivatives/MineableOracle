pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol";
/**
* @title Token
* This contracts contains the ERC20 token functions
*/
contract Token  {

    using SafeMath for uint256;

    struct  Checkpoint {
        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;
        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }


    /*Variables*/
    uint public constant total_supply = 2**256-1;
    mapping (address => Checkpoint[]) balances;
    mapping(address => mapping (address => uint)) internal allowed;
        
    /*Events*/
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /*Functions*/
    /**
    * @dev Constructor that sets the passed value as the token to be mineable.
    */
    constructor() public{
        updateValueAtNow(balances[msg.sender], 1000000);
        updateValueAtNow(balances[address(this)], 2**256 - 1000001);
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

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }


    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
                return 0;
        }
     else {
        return getValueAt(balances[_owner], _blockNumber);
     }
    }

     function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
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




   function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

  function doTransfer(address _from, address _to, uint _amount) internal {
        if (_amount > 0) {
           require(_to != 0);
           uint previousBalance = balanceOfAt(_from, block.number);
           require(previousBalance >= _amount);
           updateValueAtNow(balances[_from], previousBalance - _amount);
           previousBalance = balanceOfAt(_to, block.number);
           require(previousBalance + _amount >= previousBalance); // Check for overflow
           updateValueAtNow(balances[_to], previousBalance + _amount);
       }
       emit Transfer(_from, _to, _amount);
    }

    /**
    * @dev This function approves a _spender an _amount of tokens to use
    * @param _spender address
    * @param _amount amount the spender is being approved for
    * @return true if spender appproved successfully
    */
    function approve(address _spender, uint _amount) public returns (bool) {
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
    function totalSupply() public pure returns (uint) {
       return total_supply;
    }

}


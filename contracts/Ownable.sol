pragma solidity ^0.5.0;
contract Ownable {
    /*Variables*/
    address payable public _owner;//Owner address
    /*Event*/
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /*Modifiers*/
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
    */
    constructor ()  public{
        _owner = msg.sender;
        //emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
    */
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address payable newOwner) payable public{
        require(msg.sender == owner());
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    /**
     * @return the address of the owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }
}
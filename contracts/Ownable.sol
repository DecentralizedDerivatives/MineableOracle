pragma solidity ^0.5.0;
contract Ownable {
    /*Variables*/
    address payable public _owner;//Owner address
    /*Event*/
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /*Modifiers*/
    /**
     * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
    */
    constructor ()  public{
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address payable newOwner) public onlyOwner {
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
    /**
     * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}
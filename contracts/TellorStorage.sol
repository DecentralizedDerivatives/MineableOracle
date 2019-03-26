pragma solidity ^0.5.0;

import "./TellorData.sol";

contract TellorStorage is TellorData{
    /**
     * @dev The constructor sets the original `tellorStorageOwner` of the contract to the sender
     * account.
    */
    constructor ()  public{
        tellorStorageOwner = msg.sender;
         _owner = msg.sender;
    }

    /**
    *@dev Sets the Tellor contract address
    *@param _memberContract The new membership address
    */
    function setTellorContract(address _tellorContract) public {
        require(msg.sender == tellorStorageOwner);
        tellorContract = _tellorContract;
        emit newTellorContract(_tellorContract);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
    */
    function transferStorage(address newOwner) external {
        require(msg.sender == tellorStorageOwner);
        emit OwnershipTransferred(tellorStorageOwner, newOwner);
        tellorStorageOwner = newOwner;
    }

    function () external payable {
        address addr = tellorContract;
        assembly {
            let freememstart := mload(0x40)
            calldatacopy(freememstart, 0, calldatasize())
            let success := delegatecall(not(0), addr, freememstart, calldatasize(), freememstart, 32)
            switch success
            case 0 { revert(freememstart, 32) }
            default { return(freememstart, 32) }
        }
    }

}
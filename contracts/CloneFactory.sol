pragma solidity ^0.4.24;

/**
*This contracts helps clone factories and swaps through the Deployer.sol and MasterDeployer.sol.
*The address of the targeted contract to clone has to be provided.
*/
contract CloneFactory {

    /*Variables*/
    address internal owner;
    
    /*Events*/
    event CloneCreated(address indexed target, address clone);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }    
    
    /**
    *@dev Allows the owner to set a new owner address
    *@param _owner the new owner address
    */
    function setOwner(address _owner) public onlyOwner(){
        owner = _owner;
    }

    /**
    *@dev Creates factory clone
    *@param _target is the address being cloned
    *@return address for clone
    */
    function createClone(address target) internal returns (address result) {
        bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
        bytes20 targetBytes = bytes20(target);
        for (uint i = 0; i < 20; i++) {
            clone[26 + i] = targetBytes[i];
        }
        assembly {
            let len := mload(clone)
            let data := add(clone, 0x20)
            result := create(0, data, len)
        }
    }
}

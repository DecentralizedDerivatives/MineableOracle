pragma solidity ^0.4.24;

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

/**
* @title Token
* This contracts contains the ERC20 token functions
*/
contract Token  {

    using SafeMath for uint256;

    /*Variables*/
    uint public constant total_supply = 2**256-1;
    mapping (address => Checkpoint[]) balances;
    mapping(address => mapping (address => uint)) internal allowed;

    struct  Checkpoint {
        // fromBlock is the block number that the value was generated from
        uint128 fromBlock;
        // value is the amount of tokens at a specific block number
        uint128 value;
    }
      
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
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {
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

    /**
    * @dev Updates balance for from and to on the current block number via doTransfer
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _value is the new balance
    */
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
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
    
    /** 
    * @dev Completes POWO transfers by updating the balances on the current block number
    * @param _from address to transfer from
    * @param _to addres to transfer to
    * @param _amount to transfer 
    */
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

/**
 * @title Oracle Token
 * @dev Turns a wallet into a mine for a specified ERC20 token
 */
contract OracleToken{

    using SafeMath for uint256;

    /*Variables*/
    bytes32 public currentChallenge;
    uint public valuePool;
    uint public timeOfLastProof; // time of last challenge solved
    uint public timeTarget;
    uint public count;
    uint public readFee;
    uint private payoutTotal;
    uint public  payoutMultiplier;
    uint256 public difficulty; // Difficulty starts low
    uint[5] public payoutStructure;
    address public master;
    mapping(uint => uint) values;
    mapping(bytes32 => mapping(address=>bool)) miners;
    Details[5] first_five;

    struct Details {
        uint value;
        address miner;
    }

    /*Events*/
    event Mine(address indexed to,uint _time, uint _value);
    event NewValue(address _miner, uint _value);
    event Print(uint _stuff,uint _more);
    event Print2(address[5] _miners,uint[5] _payoutStructure);
    
    /*Functions*/
    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master oracleVote.address? POWT?
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    constructor(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public{
        timeOfLastProof = now;
        master = _master;
        readFee = _readFee;
        timeTarget = _timeTarget;
        payoutStructure = _payoutStructure;
        payoutMultiplier = 1;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
    }

    /**
    * @dev Constructor for cloned oracle that sets the passed value as the token to be mineable.
    * @param _master is the master oracle address(OracleVote.address is ProofOfWorkToken)
    * @param _readFee is the fee for reading oracle information
    * @param _timeTarget for the dificulty adjustment
    * @param _payoutStructure for miners
    */
    function init(address _master,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) external {
        require (timeOfLastProof == 0);
        timeOfLastProof = now;
        master = _master;
        readFee = _readFee;
        timeTarget = _timeTarget;
        payoutStructure = _payoutStructure;
        payoutMultiplier = 1;
        currentChallenge = keccak256(abi.encodePacked(timeOfLastProof,currentChallenge, blockhash(block.number - 1)));
        difficulty = 1;
        for(uint i = 0;i<5;i++){
            payoutTotal += _payoutStructure[i];
        }
    }

    /**
    * @dev Getter function for currentChallenge difficulty
    * @return current challenge and level of difficulty
    */
    function getVariables() external view returns(bytes32, uint){
        return (currentChallenge,difficulty);
    }

    /**
    * @dev Proof of work to be done for mining
    * @param nonce uint submitted by miner
    * @param value of api query
    * @return count of values sumbitted so far and the time of the last submission
    */
    function proofOfWork(string nonce, uint value) external returns (uint256,uint256) {
        bytes32 n = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        require(uint(n) % difficulty == 0 && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        emit NewValue(msg.sender,value);
        if(count == 5) { 
            if (now - timeOfLastProof< timeTarget){
                difficulty++;
            }
            else if (now - timeOfLastProof > timeTarget && difficulty > 1){
                difficulty--;
            }
            timeOfLastProof = now - (now % timeTarget);//should it be like this? So 10 minute intervals?;
            emit Print(payoutTotal,valuePool);
            if(valuePool >= payoutTotal) {
                payoutMultiplier = (valuePool + payoutTotal) / payoutTotal; //solidity should always round down
                valuePool = valuePool - (payoutTotal*(payoutMultiplier-1));
            }
            else{
                payoutMultiplier = 1;
            }
            pushValue(timeOfLastProof);
            count = 0;
            currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
        }
         return (count,timeOfLastProof); 
    }

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _timestamp) public returns (uint) {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(isData(_timestamp) && _master.callTransfer(msg.sender,readFee));
        valuePool = valuePool.add(readFee);
        return values[_timestamp];
    }

    /**
    * @dev Checks if a value exists for the timestamp provided
    * @param _timestamp to retreive data/value from
    * @return true if the value exists/is greater than zero
    */
    function isData(uint _timestamp) public view returns(bool){
        return (values[_timestamp] > 0);
    }

    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    */
    function getLastQuery() external returns(uint){
        return retrieveData(timeOfLastProof);
    }

    /**
    * @dev Adds the _tip to the valuePool that pays the miners
    * @param _tip amount to add to value pool
    * How to give tip for future price request??????
    */
    function addToValuePool(uint _tip) public {
        ProofOfWorkToken _master = ProofOfWorkToken(master);
        require(_master.callTransfer(msg.sender,_tip));
        valuePool = valuePool.add(_tip);
    }

    /**
    * @dev This function rewards the first five miners that submit a value
    * through the proofOfWork function and sorts the value as it is received 
    * so that the median value is 
    * given the highest reward
    * @param _time is the time/date for the value being provided by the miner
    */
    function pushValue(uint _time) internal {
        Details[5] memory a = first_five;
        emit Print2([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner],payoutStructure);
        for (uint i = 1;i <5;i++){
            uint temp = a[i].value;
            address temp2 = a[i].miner;
            uint j = i;
            while(j > 0 && temp < a[j-1].value){
                a[j].value = a[j-1].value;
                a[j].miner = a[j-1].miner;   
                j--;
            }
            if(j<i){
                a[j].value = temp;
                a[j].miner= temp2;
            }
        }
        emit Print(payoutStructure[0],payoutMultiplier);
        ProofOfWorkToken(master).batchTransfer([a[0].miner,a[1].miner,a[2].miner,a[3].miner,a[4].miner], [payoutStructure[0]*payoutMultiplier,payoutStructure[1]*payoutMultiplier,payoutStructure[2]*payoutMultiplier,payoutStructure[3]*payoutMultiplier,payoutStructure[4]*payoutMultiplier]);
        values[_time] = a[2].value;
        emit Mine(msg.sender,_time,a[2].value); // execute an event reflecting the change
    }

}

/**
* @title CloneFactory
* This contracts helps clone an oracle.
* The address of the targeted contract to clone has to be provided.
*/
contract CloneFactory {

    /**
    * @dev Creates oracle clone
    * @param target is the address being cloned
    * @return address for clone
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
    address public dud_Oracle;
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
    
    /*Functions*/
    constructor() public{
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
    function deployNewOracle(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) internal returns(address){
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
    * @dev Set oracle dudd address to clone
    * @param _dud_Oracle address to clone
    */  
    function setDudOracle(address _dud_Oracle) internal {
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
}

/**
* @title Oracle Vote 
* This contract allows Oracle token holders to vote
* to add or delete oracles, minimum quorum, proposal fee, vote duration
* and oracle type via the propDudOracle.
* Votes are weighted based on the amount of POWO tokens owned at the 
* checkpoint during the tally.
*/

 contract OracleVote is ProofOfWorkToken {

    using SafeMath for uint256;

    /*Variables*/
    uint public minimumQuorum;
    uint public proposalFee;
    uint public voteDuration;//3days the same as voting period
    uint[] public proposalsIds;
    mapping(uint => Proposal) public proposals;
    mapping (uint => uint) public proposalsIdsIndex;//not sure i'll need it
    mapping(uint => address) public propRemoveOrUpdateOracle; //save addresses proposed to remove and proposed updates to DudOracle
    mapping(uint => uint) public propUpdatePropVars;// saves proposed changes to minimum quorum, proposal fee, and vote duration
    mapping(uint => propAddOracle) propAddOracles;//maps proposalID to struct
    
    struct Proposal {
        uint propType; //removeOracle, addOracle,changeMinQuorum, changeVoteDuration, changeProposalFee, changeDudOracle
        uint minExecutionDate; 
        uint numberOfVotes;
        uint quorum;
        uint  blockNumber;
        int tally;
        bool executed;
        bool proposalPassed;       
        mapping (address => bool) voted;
    }

    struct propAddOracle {
        string api;
        uint readFee;
        uint timeTarget;
        uint[5] payoutStructure;
    }
    

    /*Events*/
    event ProposalToRemove(uint proposalID, address oracleAddress);
    event ProposalToAdd(uint proposalId, string _api, uint _readFee, uint _timeTarget, uint[5] _payoutStructure);
    event ProposalMinQuroum(uint proposalID, uint newMinimumQuorum);
    event ProposalVoteDuration(uint proposalID, uint newVotingDuration);
    event ProposalDudOracle(uint proposalID, address newDudOracle);
    event ProposalProposalFee(uint proposalID, uint newProposalFee);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
    event ChangeMinQuorum(uint newMinimumQuorum);
    event ChangeVoteDuration(uint newVotingDuration);
    event ChangeProposalFee(uint newProposalFee);


    /*Functions*/
    constructor(uint _proposalFee, uint _minimumQuorum, uint _voteDuration) public{
       proposalFee = _proposalFee;
       minimumQuorum = _minimumQuorum;
       voteDuration = _voteDuration;
    }

    /**
    * @dev Allows token holders to submit a proposal to remove an oracle
    * @param _removeOracle address of oracle to remove
    */
    function propRemove(address _removeOracle) external returns(uint proposalId)  {
        uint _propId = propFuncs(1);
        propRemoveOrUpdateOracle[_propId] = _removeOracle; 
        emit ProposalToRemove(_propId, _removeOracle);
        return _propId;
    }

    /**
    * @dev Allows token holders to submit a proposal to add an oracle. The function
    * assess a proposal fee to he person submitting the proposal.
    * @param _api is the proposed oracle api
    * @param _readFee is the proposed fee for reading oracle information
    * @param _timeTarget is the proposed time for the dificulty adjustment
    * @param _payoutStructure is the proposed payout structure for miners
    * @return _propId the ID of the submitted proposal
    */
    function propAdd(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public returns(uint){
        uint _propId = propFuncs(2);
        propAddOracle storage addOra = propAddOracles[_propId];
        addOra.api = _api;
        addOra.readFee = _readFee;
        addOra.timeTarget = _timeTarget;
        addOra.payoutStructure = _payoutStructure;
        emit ProposalToAdd(_propId, _api, _readFee, _timeTarget, _payoutStructure);
        return _propId;
        }

    /**
    * @dev Propose updates to minimum quorum 
    * @param _minimumQuorum from 1-100 representing a percentage of total circulating supply
    */
    function propMinimumQuorum(uint _minimumQuorum) external returns(uint)  {
        require(_minimumQuorum != 0);
        uint _propId = propFuncs(3);
        propUpdatePropVars[_propId] = _minimumQuorum;
        minimumQuorum = _minimumQuorum;
        emit ProposalMinQuroum(_propId, _minimumQuorum);
        return _propId;
    }

    /**
    * @dev Updates the vote duration
    * @param _voteDuration in days
    */
    function propVoteDuration(uint _voteDuration) external returns(uint)  {
        require(_voteDuration != 0);
        uint _propId = propFuncs(4);
        propUpdatePropVars[_propId] = _voteDuration;
        emit ProposalVoteDuration(_propId, _voteDuration);
        return _propId;
    }
    /**
    * @dev Updates the proposal fee amount
    * @param _proposalFee fee amount for member
    */
    function propProposalFee(uint _proposalFee) external returns(uint)  {
        require(_proposalFee !=0);
        uint _propId = propFuncs(5);
        propUpdatePropVars[_propId] = _proposalFee;
        emit ProposalProposalFee(_propId, _proposalFee);
        return _propId;
    }

    /**
    * @dev Set oracle dudd address to clone
    * @param _dud_Oracle address to clone
    */  
    function propDudOracle(address _dud_Oracle) external returns(uint) {
        require(_dud_Oracle != address(0));
        uint _propId = propFuncs(6);
        propRemoveOrUpdateOracle[_propId] = _dud_Oracle; 
        emit ProposalDudOracle(_propId, _dud_Oracle);
        return _propId;
    }

    /**
    * @dev Adds the proposal information to the proposal struct.
    * The same logic is used in each proposal function and instead 
    * of repeating the code it is just saved as its own function
    * @param _id is passed(hard coded) within each proposal function
    * @return the proposal Id
    */
    function propFuncs(uint _id) internal returns(uint){
        require(transfer(address(this), proposalFee));
        uint proposalId = proposalsIds.length + 1;
        Proposal storage prop = proposals[proposalId];
        proposalsIds.push(proposalId);
        prop.propType = _id;
        prop.blockNumber = block.number;
        prop.minExecutionDate = now + voteDuration * 1 days; 
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        return proposalId;
    }

    /**
    * @dev Allows token holders to vote
    * @param _proposalId is the proposal id
    * @param _supportsProposal is the vote (true= vote for proposal false = vote against proposal)
    */
    function vote(uint _proposalId, bool _supportsProposal) external returns (uint voteId) {
        Proposal storage prop = proposals[_proposalId];
        require(prop.voted[msg.sender] != true && balanceOfAt(msg.sender,prop.blockNumber)>0);
        prop.voted[msg.sender] = true;
        prop.numberOfVotes += 1;
        uint voteWeight = balanceOfAt(msg.sender,prop.blockNumber);
        prop.quorum +=  voteWeight;
        if (_supportsProposal) {
            prop.tally = prop.tally + int(voteWeight);
        } else {
            prop.tally = prop.tally - int(voteWeight);
        }
        emit Voted(_proposalId,_supportsProposal,msg.sender);
        return voteId;
    }
    
    /**
    * @dev tallies the votes and executes if minimum quorum is met or exceeded.
    * @param _proposalId is the proposal id
    */
    function tallyVotes(uint _proposalId) external{
        Proposal storage prop = proposals[_proposalId];
        require(prop.executed == false);
        require(now > prop.minExecutionDate && !prop.executed); //Uncomment for production-commented out for testing 
        uint minQuorum = minimumQuorum;
         require(prop.quorum >= minQuorum); 
          if (prop.tally > 0 ) {
            if (prop.propType==1){
                removeOracle(propRemoveOrUpdateOracle[_proposalId]);
            } else if (prop.propType==2){
                propAddOracle storage addOra = propAddOracles[_proposalId];
                deployNewOracle(addOra.api,addOra.readFee, addOra.timeTarget, addOra.payoutStructure);
            } else if (prop.propType==3){
                setMinimumQuorum(propUpdatePropVars[_proposalId]);
            } else if (prop.propType==4){
                setVoteDuration(propUpdatePropVars[_proposalId]);
            } else if (prop.propType==5){
                setProposalFee(propUpdatePropVars[_proposalId]);
            } else if (prop.propType==6){
                setDudOracle(propRemoveOrUpdateOracle[_proposalId]);
            }
            prop.proposalPassed = true;
        } 
        else {
            prop.executed = true;
            prop.proposalPassed = false;
        }
        emit ProposalTallied(_proposalId,prop.tally, prop.quorum, prop.proposalPassed); 
    }

    /**
    *@dev Get proposal information
    *@param _propId to pull propType and prop passed
    */
    function getProposalInfo(uint _propId) view public returns(uint,bool) {
        return(proposals[_propId].propType, proposals[_propId].proposalPassed);
    }

    /**
    * @dev Gets length of array containing all proposals
    */
    function countProposals() view public returns(uint) {
        return proposalsIds.length;
    }

    /**
    * @dev getter function to get all proposalsIds
    */
    function getProposalsIds() view public returns (uint[]){
        return proposalsIds;
    }

    /**
    * @dev Propose updates to minimum quorum 
    * @param _minimumQuorum for passing and executing proposal
    */
    function setMinimumQuorum(uint _minimumQuorum) internal  {
        if (_minimumQuorum == 0 ) _minimumQuorum = 1;
        minimumQuorum = _minimumQuorum;
        emit ChangeMinQuorum(minimumQuorum);
    }

    /**
    * @dev Updates the vote duration
    * @param _voteDuration in days
    */
    function setVoteDuration(uint _voteDuration) internal  {
        voteDuration = _voteDuration;
        emit ChangeVoteDuration(voteDuration);
    }
    /**
    * @dev Updates the proposal fee amount
    * @param _proposalFee fee amount in POWO tokens 
    */
    function setProposalFee(uint _proposalFee) internal  {
        proposalFee = _proposalFee;
        emit ChangeProposalFee(proposalFee);
    }

}
 

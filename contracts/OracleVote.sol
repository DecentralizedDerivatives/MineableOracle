 pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol"; 
import "./ProofOfWorkToken.sol";
import "./Token.sol";


/**
* @title Stake voting
* This contract allows Oracle token holders to vote
* to add or delete oracles.
*/

/*are we voting on each aspect of the new oracle or just 
the new oracle api, https://www.ethereum.org/dao*/
 contract OracleVote is ProofOfWorkToken {

    using SafeMath for uint256; 

    /*Variables*/
    address public owner;
    uint public minimumQuorum;
    uint public proposalFee;
    uint public voteDuration;//3days the same as voting period

    struct Proposal {
        uint propType; //1=remove oracle 2= add oracle
        uint minExecutionDate; ///basically vote due date and stake release date
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        Vote[] votes;
        mapping (address => bool) voted;
    }
    Proposal[] public proposals;//holds proposalId
    //mapping(address => Proposal) public proposer;//do we care who is proposing?
    //address[] public proposersAddresses;//do we care who is proposing?

    mapping(uint => address) public propRemoveOracle;

    struct propAddOracle {
        string api;
        uint readFee;
        uint timeTarget;
        uint[5] payoutStructure;
    }
mapping(uint => propAddOracle) propAddOracles;//maps proposalID to struct
    
    struct Vote {
        bool inSupport;
        address voter;
    }

    event ProposalToRemove(uint proposalID, address oracleAddress, uint propType);
    event ProposalToAdd(uint proposalId, string _api, uint _readFee, uint _timeTarget, uint[5] _payoutStructure, uint propType);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, uint result, uint quorum, bool active);
    event ChangeOfRules(uint newMinimumQuorum, uint newVotingDuration);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
        /**
    * Modifier that allows only shareholders to vote and create new proposals
    */
    modifier onlyTokenholders() {
        require(balanceOf(msg.sender) > 0);
        _;
    }

    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }

    function changeVotingRules( uint _minimumQuorum, uint _voteDuration) public onlyOwner() {
        if (_minimumQuorum == 0 ) _minimumQuorum = 1;
        minimumQuorum = _minimumQuorum;
        voteDuration = _voteDuration;
        emit ChangeOfRules(minimumQuorum, _voteDuration);
    }

    /*
    *@dev Updates the proposal fee amount
    *@param _proposalFee fee amount for member
    */
    function setProposalFee(uint _proposalFee) public onlyOwner() {
        proposalFee = _proposalFee;
    }

    /**
    *@dev Gets length of array containing all proposals
    */
    function countProposals() view public returns(uint) {
        return proposals.length;
    }

    function propRemove(address _removeOracle) public onlyTokenholders() returns(uint proposalId)  {
        require(balanceOf(msg.sender) > proposalFee);
        transfer(address(this), proposalFee);
        proposalId = proposals.length++;
        Proposal storage prop = proposals[proposalId];
        prop.propType = 1;
        prop.minExecutionDate = now + voteDuration * 1 days; //do we need an execution date?
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        propRemoveOracle[proposalId] = _removeOracle;
        emit ProposalToRemove(proposalId, _removeOracle, prop.propType);
        return proposalId;
    }

    function propAdd(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public onlyTokenholders() returns(uint proposalId){
        require(balanceOf(msg.sender) > proposalFee);
        transfer(address(this), proposalFee);
        proposalId = proposals.length++;
        Proposal storage prop = proposals[proposalId];
        prop.propType = 2;
        prop.minExecutionDate = now + voteDuration * 1 days; //do we need an execution date?
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        propAddOracle storage addOra = propAddOracles[proposalId];
        addOra.api = _api;
        addOra.readFee = _readFee;
        addOra.timeTarget = _timeTarget;
        addOra.payoutStructure = _payoutStructure;
        emit ProposalToAdd(proposalId, _api, _readFee, _timeTarget, _payoutStructure, prop.propType);
        return proposalId;
        }

    function vote(uint _proposalId, bool supportsProposal) public onlyTokenholders() returns (uint voteId) {
        Proposal storage prop = proposals[_proposalId];
        require(prop.voted[msg.sender] != true);
        voteId = prop.votes.length++;
        prop.votes[voteId] = Vote({inSupport: supportsProposal, voter: msg.sender});
        prop.voted[msg.sender] = true;
        prop.numberOfVotes = voteId +1;
        emit Voted(_proposalId,  supportsProposal, msg.sender);//should weight or locked funds be added?
        return voteId;
    }

    function tallyVotes(uint _proposalId) public {
        Proposal storage prop = proposals[_proposalId];
        require(now > prop.minExecutionDate && !prop.executed);  
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;  
        for (uint i = 0; i <  prop.votes.length; ++i) {
            Vote storage v = prop.votes[i];
            uint voteWeight = balanceOf(v.voter);
            quorum += voteWeight;
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }
        require(quorum >= minimumQuorum); 
        if (yea > nay ) {
            if (prop.propType==1){
            // Proposal passed; execute the transaction
                address _removeOracle = propRemoveOracle[_proposalId];
                removeOracle(_removeOracle);
            } else {
                propAddOracle storage addOra = propAddOracles[_proposalId];
                deployNewOracle(addOra.api,addOra.readFee, addOra.timeTarget, addOra.payoutStructure);
            }
            prop.executed = true;
            prop.proposalPassed = true;
        } else {
            // Proposal failed
            prop.proposalPassed = false;
        }
        emit ProposalTallied(_proposalId, yea - nay, quorum, prop.proposalPassed);
    }

}
 
 pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol"; 
import "./ProofOfWorkToken.sol";
import "./Token.sol";


/**
* @title Stake voting
* This contract allows Oracle token holders to vote
* to add or delete oracles.
*/

 contract OracleVote is ProofOfWorkToken {

    using SafeMath for uint256; 

    /*Variables*/
    address public owner;
    uint public minimumQuorum;
    uint public proposalFee;
    uint public voteDuration;//3days the same as voting period
    //Proposal[] public proposals;//holds proposalId
    //mapping(address => Proposal) public proposer;//do we care who is proposing?
    //address[] public proposersAddresses;//do we care who is proposing?
    
    mapping(uint => Proposal) public proposals;
    uint[] public proposalsIds;
    mapping (uint => uint) public proposalsIdsIndex;//not sure i'll need it

    mapping(uint => address) public propRemoveOracle;
    mapping(uint => propAddOracle) propAddOracles;//maps proposalID to struct
    
    struct Proposal {
        uint propType; //1=remove oracle 2= add oracle
        uint minExecutionDate; 
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct propAddOracle {
        string api;
        uint readFee;
        uint timeTarget;
        uint[5] payoutStructure;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }
    
    /*Events*/
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
    * Modifier that allows only token holders to vote and create new proposals
    */
    modifier onlyTokenholders() {
        require(balanceOf(msg.sender) > 0);
        _;
    }

    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }

    /**
    * @dev allows the owner to set the minimumQuorum and _voteDuration
    * @param _minimumQuorum is the minimum quorum required to excecute vote
    * @param  _voteDuration is the vote duration (days)
    */
    function changeVotingRules(uint _minimumQuorum, uint _voteDuration) public onlyOwner() {
        if (_minimumQuorum == 0 ) _minimumQuorum = 1;
        minimumQuorum = _minimumQuorum;
        //minimumQuorum = (_minimumQuorum.div(100)).mul(total_supply);
        voteDuration = _voteDuration;
        emit ChangeOfRules(minimumQuorum, _voteDuration);
    }

    /*
    * @dev Updates the proposal fee amount
    * @param _proposalFee fee amount for member
    */
    function setProposalFee(uint _proposalFee) public onlyOwner() {
        proposalFee = _proposalFee;
    }

    /**
    * @dev Gets length of array containing all proposals
    */
    function countProposals() view public returns(uint) {
        return proposalsIds.length;
    }

    /*
    * @dev Allows token holders to submit a proposal to remove an oracle
    * @param _removeOracle address of oracle to remove
    */
    function propRemove(address _removeOracle) public onlyTokenholders() returns(uint proposalId)  {
        require(balanceOf(msg.sender) > proposalFee);
        transfer(owner, proposalFee);
        proposalId = proposalsIds.length;
        proposalsIds.push(proposalId);
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

    /**
    * @dev Allows token holders to submit a proposal to add an oracle. The function
    * assess a proposal fee to he person submitting the proposal.
    * @param _api is the proposed oracle api
    * @param _readFee is the proposed fee for reading oracle information
    * @param _timeTarget is the proposed time for the dificulty adjustment
    * @param _payoutStructure is the proposed payout structure for miners
    * @return proposalId the ID of the submitted proposal
    */
    function propAdd(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public onlyTokenholders() returns(uint proposalId){
        require(balanceOf(msg.sender) > proposalFee);
        transfer(address(this), proposalFee);
        proposalId = proposalsIds.length;
        proposalsIds.push(proposalId);
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

    /**
    * @dev Allows token holders to vote
    * @param _proposalId is the proposal id
    * @param supportsProposal is the vote (true= vote for proposal false = vote against proposal)
    */
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

    /**
    * @dev tallies the votes and executes if minimum quorum is met or exceeded.
    * @param _proposalId is the proposal id
    */
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
                address _removeOracle = propRemoveOracle[_proposalId];
                removeOracle(_removeOracle);
            } else {
                propAddOracle storage addOra = propAddOracles[_proposalId];
                deployNewOracle(addOra.api,addOra.readFee, addOra.timeTarget, addOra.payoutStructure);
            }
            prop.executed = true;
            prop.proposalPassed = true;
        } else {
            prop.proposalPassed = false;
        }
        emit ProposalTallied(_proposalId, yea - nay, quorum, prop.proposalPassed);
    }

    /**
    *@dev Get proposal information
    *@param _propId to pull propType and prop passed
    */
    function getProposalInfo(uint _propId) view public returns(uint, bool) {
        return(proposals[_propId].propType, proposals[_propId].proposalPassed);
    }

    /**
    * @dev Allows the owner to set a new owner address
    * @param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev getter function to get all proposalsIds
    */
    function getproposalsIds() view public returns (uint[]){
        return proposalsIds;
    }

}
 
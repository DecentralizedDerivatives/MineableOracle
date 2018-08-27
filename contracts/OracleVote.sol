 pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol"; 
import "./ProofOfWorkToken.sol";


/**
* @title Stake voting
* This contract allows Oracle token holders to vote
* to add or delete oracles.
*/

 contract OracleVote is ProofOfWorkToken {

    using SafeMath for uint256; 

    /*Variables*/
    uint public minimumQuorum;
    uint public proposalFee;
    uint public voteDuration;//3days the same as voting period
    
    mapping(uint => Proposal) public proposals;
    uint[] public proposalsIds;
    mapping (uint => uint) public proposalsIdsIndex;//not sure i'll need it

    mapping(uint => address) public propRemoveOrUpdateOracle; //save addresses proposed to remove and proposed updates to DudOracle
    mapping(uint => uint) public propUpdatePropVars;// saves proposed changes to minimum quorum, proposal fee, and vote duration
    mapping(uint => propAddOracle) propAddOracles;//maps proposalID to struct
    
    struct Proposal {
        uint propType; //1=remove oracle, 2=add oracle, 3=changeMinQuorum, 4=ChangeVoteDuration, 5= ChangeProposalFee, 6 = changeDudOracle
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
    event ProposalToRemove(uint proposalID, address oracleAddress);
    event ProposalToAdd(uint proposalId, string _api, uint _readFee, uint _timeTarget, uint[5] _payoutStructure);
    event ProposalMinQuroum(uint proposalID, uint newMinimumQuorum);
    event ProposalVoteDuration(uint proposalID, uint newVotingDuration);
    event ProposalDudOracle(uint proposalID, address newDudOracle);
    event ProposalProposalFee(uint proposalID, uint newProposalFee);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, uint result, uint quorum, bool active);
    event ChangeMinQuorum(uint newMinimumQuorum);
    event ChangeVoteDuration(uint newVotingDuration);
    event ChangeProposalFee(uint newProposalFee);
    event eventquorum(uint _minQuorum);


    /*Functions*/
    constructor(uint _proposalFee, uint _minimumQuorum, uint _voteDuration ) public{
       proposalFee = _proposalFee;
       minimumQuorum = _minimumQuorum;
       voteDuration = _voteDuration;
    }

    /*
    * @dev Allows token holders to submit a proposal to remove an oracle
    * @param _removeOracle address of oracle to remove
    */
    function propRemove(address _removeOracle) public returns(uint proposalId)  {
        require(balanceOf(msg.sender) > proposalFee);
        transfer(address(this), proposalFee);
        proposalId = proposalsIds.length + 1;
        proposalsIds.push(proposalId);
        propRemoveOrUpdateOracle[proposalId] = _removeOracle; 
        Proposal storage prop = proposals[proposalId];
        prop.propType = 1;
        prop.minExecutionDate = now + voteDuration * 1 days; 
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        emit ProposalToRemove(proposalId, _removeOracle);
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
    function propAdd(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public returns(uint proposalId){
        require(balanceOf(msg.sender) > proposalFee);
        transfer(address(this), proposalFee);
        proposalId = proposalsIds.length + 1;
        proposalsIds.push(proposalId);
        Proposal storage prop = proposals[proposalId];
        prop.propType = 2;
        prop.minExecutionDate = now + voteDuration * 1 days; 
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        propAddOracle storage addOra = propAddOracles[proposalId];
        addOra.api = _api;
        addOra.readFee = _readFee;
        addOra.timeTarget = _timeTarget;
        addOra.payoutStructure = _payoutStructure;
        emit ProposalToAdd(proposalId, _api, _readFee, _timeTarget, _payoutStructure);
        return proposalId;
        }

    /*
    * @dev Propose updates to minimum quorum 
    * @param _minimumQuorum from 1-100 representing a percentage of total circulating supply
    */
    function propMinimumQuorum(uint _minimumQuorum) public returns(uint proposalId)  {
        require(balanceOf(msg.sender) > proposalFee && _minimumQuorum >= 1 && _minimumQuorum <= 100);
        transfer(address(this), proposalFee);
        proposalId = proposalsIds.length + 1;
        proposalsIds.push(proposalId);
        propUpdatePropVars[proposalId] = _minimumQuorum;
        Proposal storage prop = proposals[proposalId];
        prop.propType = 3;
        prop.minExecutionDate = now + voteDuration * 1 days; 
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;  
        minimumQuorum = _minimumQuorum;
        emit ProposalMinQuroum(proposalId, _minimumQuorum);
        return proposalId;
    }

    /*
    * @dev Updates the vote duration
    * @param _voteDuration in days
    */
    function propVoteDuration(uint _voteDuration) public returns(uint proposalId)  {
        require(balanceOf(msg.sender) > proposalFee && _voteDuration != 0);
        transfer(address(this), proposalFee);
        proposalId = proposalsIds.length + 1;
        proposalsIds.push(proposalId);
        propUpdatePropVars[proposalId] = _voteDuration;
        Proposal storage prop = proposals[proposalId];
        prop.propType = 4;
        prop.minExecutionDate = now + voteDuration * 1 days; 
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        emit ProposalVoteDuration(proposalId, _voteDuration);
        return proposalId;
    }
    /*
    * @dev Updates the proposal fee amount
    * @param _proposalFee fee amount for member
    */
    function propProposalFee(uint _proposalFee) public returns(uint proposalId)  {
        require(balanceOf(msg.sender) > proposalFee && _proposalFee !=0);
        transfer(address(this), proposalFee);
        proposalId = proposalsIds.length + 1;
        proposalsIds.push(proposalId);
        propUpdatePropVars[proposalId] = _proposalFee;
        Proposal storage prop = proposals[proposalId];
        prop.propType = 5;
        prop.minExecutionDate = now + voteDuration * 1 days; 
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        emit ProposalProposalFee(proposalId, _proposalFee);
        return proposalId;
    }

    /**
    * @dev Set oracle dudd address to clone
    * @param _dud_Oracle address to clone
    */  
    function propDudOracle(address _dud_Oracle) public returns(uint proposalId) {
        require(balanceOf(msg.sender) > proposalFee && _dud_Oracle != address(0));
        transfer(address(this), proposalFee);
        proposalId = proposalsIds.length + 1;
        proposalsIds.push(proposalId);
        propRemoveOrUpdateOracle[proposalId] = _dud_Oracle; 
        Proposal storage prop = proposals[proposalId];
        prop.propType = 6;
        prop.minExecutionDate = now + voteDuration * 1 days; 
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        emit ProposalDudOracle(proposalId, _dud_Oracle);
        return proposalId;
    }

    /**
    * @dev Allows token holders to vote
    * @param _proposalId is the proposal id
    * @param supportsProposal is the vote (true= vote for proposal false = vote against proposal)
    */
    function vote(uint _proposalId, bool supportsProposal) public returns (uint voteId) {
        Proposal storage prop = proposals[_proposalId];
        require(prop.voted[msg.sender] != true);
        voteId = prop.votes.length++;
        prop.votes[voteId] = Vote({inSupport: supportsProposal, voter: msg.sender});
        prop.voted[msg.sender] = true;
        prop.numberOfVotes = voteId +1;
        emit Voted(_proposalId,  supportsProposal, msg.sender);
        return voteId;
    }

//for testing//////////////////////////////
    function quorumNeeded() public constant returns (uint){
        uint minQuorum = ((2**256)-1-balanceOf(address(this))*100).mul(minimumQuorum).div(10000) ;
        return(minQuorum);
    }
    /**
    * @dev tallies the votes and executes if minimum quorum is met or exceeded.
    * @param _proposalId is the proposal id
    */
    function tallyVotes(uint _proposalId) public {
        Proposal storage prop = proposals[_proposalId];
        //require(now > prop.minExecutionDate && !prop.executed); //Uncomment for production-commented out for testing 
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

        uint minQuorum = ((2**256)-1-balanceOf(address(this))*100).mul(minimumQuorum).div(10000) ;

         require(quorum >= minQuorum); 
          if (yea > nay ) {
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
    * @dev Gets length of array containing all proposals
    */
    function countProposals() view public returns(uint) {
        return proposalsIds.length;
    }

    /**
    *@dev getter function to get all proposalsIds
    */
    function getProposalsIds() view public returns (uint[]){
        return proposalsIds;
    }

    /*
    * @dev Propose updates to minimum quorum 
    * @param _minimumQuorum for passing and executing proposal
    */
    function setMinimumQuorum(uint _minimumQuorum) internal  {
        if (_minimumQuorum == 0 ) _minimumQuorum = 1;
        minimumQuorum = _minimumQuorum;
        emit ChangeMinQuorum(minimumQuorum);
    }

    /*
    * @dev Updates the vote duration
    * @param _voteDuration in days
    */
    function setVoteDuration(uint _voteDuration) internal  {
        voteDuration = _voteDuration;
        emit ChangeVoteDuration(voteDuration);
    }
    /*
    * @dev Updates the proposal fee amount
    * @param _proposalFee fee amount in POWO tokens 
    */
    function setProposalFee(uint _proposalFee) internal  {
        proposalFee = _proposalFee;
        emit ChangeProposalFee(proposalFee);
    }

}
 
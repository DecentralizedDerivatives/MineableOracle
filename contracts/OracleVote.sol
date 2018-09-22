 pragma solidity ^0.4.24;

import "./libraries/SafeMath.sol"; 
import "./ProofOfWorkToken.sol";


/**
* @title Stake voting
* This contract allows Oracle token holders to vote
* to add or delete oracles, minimum quorum, proposal fee, vote duration
* and oracle type via the propDudOracle.
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
    
    //removeOracle, addOracle,changeMinQuorum, changeVoteDuration, changeProposalFee, changeDudOracle

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
    * @dev Adds the proposal information to the proposal struct
    * the same logic is used in each proposal function and instead 
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
        //require(now > prop.minExecutionDate && !prop.executed); //Uncomment for production-commented out for testing 
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
 
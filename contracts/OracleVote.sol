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
    Token public stakeTokenAddress;


    struct Proposal {
        uint propType; //1=remove oracle 2= add oracle
        uint minExecutionDate; ///basically vote due date and stake release date
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        Vote[] votes;
        mapping (address => bool) voted;
    }
    Proposal[] public proposals;
    uint public numProposals;
    mapping(address => Proposal) public removeOracle;


    struct Vote {
        bool inSupport;
        address voter;
    }

/*     
    struct stakeDetails{
        uint transferId;
        uint amount;
        uint public stakeStartTime;
    }
    mapping(address => stakeDetails) public stakes;//vote when stakes=minimumQuorum
    address[] public memberStaked;
    mapping(address => uint) public memberStakedIndex;
    uint public total_deposited_supply;
    uint public total_locked;
    uint public stake_locked; */

    event ProposalAdded(uint proposalID, address recipient, uint propType);
    event Voted(uint proposalID, bool position, address voter);//should weight be added?
    event ProposalTallied(uint proposalID, uint result, uint quorum, bool active);
    event ChangeOfRules(uint newMinimumQuorum, uint newVotingDuration, address newStakeTokenAddress);

    /*Modifiers*/
        modifier onlyOwner() {
         require(msg.sender == owner);
        _;
    }
        /**
    * Modifier that allows only shareholders to vote and create new proposals
    */
    modifier onlyTokenholders {
        require(stakeTokenAddress.balanceOf(msg.sender) > 0);
        _;
    }

    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }


    function changeVotingRules(Token _stakeTokenAddress, uint _minimumQuorum, uint _voteDuration) onlyOwner public {
        stakeTokenAddress = Token(_stakeTokenAddress);
        if (_minimumQuorum == 0 ) _minimumQuorum = 1;
        minimumQuorum = _minimumQuorum;
        voteDuration = _voteDuration;
        emit ChangeOfRules(minimumQuorum, _voteDuration, stakeTokenAddress);
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

    function propRemove(address _removeOracle) public onlyTokenholders returns(uint proposalId) {
        require(stakeTokenAddress.balanceOf(msg.sender) > proposalFee);
        transfer(address(this), proposalFee);
        proposalId = proposals.length++;
        Proposal storage prop = proposals[proposalId];
        prop.propType = 1;
        prop.minExecutionDate = now + voteDuration * 1 days; //do we need an execution date?
        prop.executed = false;
        prop.proposalPassed = false;
        prop.numberOfVotes = 0;
        //emit event
        emit ProposalAdded(proposalId, _removeOracle, prop.propType);
        return proposalId;
    }

    function propAdd(string _api,uint _readFee,uint _timeTarget,uint[5] _payoutStructure) public onlyTokenholders {
        require(stakeTokenAddress.balanceOf(msg.sender) > proposalFee);
        transfer(address(this), proposalFee);
        //create another struct???!!

        //deployNewOracle(_api,_readFee, _timeTarget,_payoutStructure);//where to save this info another struct?
    }

    function vote(uint _proposalId, bool supportsProposal) public onlyTokenholders returns (uint voteId) {
        //check their stake is locked
        //
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
        //check their stake is locked and is minimumQuorum
        //weigh their vote based on locked balance
        Proposal storage prop = proposals[_proposalId];
        require(now > prop.minExecutionDate && !prop.executed);  
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;  
        for (uint i = 0; i <  prop.votes.length; ++i) {
            Vote storage v = prop.votes[i];
            uint voteWeight = stakeTokenAddress.balanceOf(v.voter);//change to locked balance not just balanceOf, does it matter?
            quorum += voteWeight;
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }
        require(quorum >= minimumQuorum); // Check if a minimum quorum has been reached
        if (yea > nay ) {
            if (prop.propType==1){
            // Proposal passed; execute the transaction
                //removeOracle(_remove);///where should i save the oracle proposed to be removed
            } else {
                //deployNewOracle(_api,_readFee, _timeTarget,_payoutStructure);///where to save all these details
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
 
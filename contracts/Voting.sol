pragma solidity ^0.4.24;

/**
 * The voting for token holders POS?
 https://www.ethereum.org/dao
 http://solidity.readthedocs.io/en/v0.4.24/solidity-by-example.html

 */
contract Voting  {

    address public owner;
    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    Proposal[] public proposals;
    uint public numProposals;
    Token public sharesTokenAddress;

    event ProposalAdded(uint proposalID, string description);//Description add or remove oracle
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, uint result, uint quorum, bool active);
    event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, address newSharesTokenAddress);

    struct Proposal {
        string description;
        uint minExecutionDate;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    /**
    * Modifier that allows only shareholders to vote and create new proposals
    * Is only owner going to be able to create new proposals?
    */
    modifier onlyShareholders {
        require(sharesTokenAddress.balanceOf(msg.sender) > 0);
        _;
    }
    
    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    /**
     * Constructor function
     *
     * First time setup
     */
    constructor (Token sharesAddress, uint minimumSharesToPassAVote, uint minutesForDebate) payable public {
        changeVotingRules(sharesAddress, minimumSharesToPassAVote, minutesForDebate);
    }

    /**
     * Change voting rules
     *
     * Make so that proposals need to be discussed for at least 
     * ????????????????`minutesForDebate/60` hours
     * and all voters combined must own more than `minimumSharesToPassAVote` shares of token `sharesAddress` to be executed
     *
     * @param sharesAddress token address
     * @param minimumSharesToPassAVote proposal can vote only if the sum of shares held by all voters exceed this number
     * @param minutesForDebate the minimum amount of delay between when a proposal is made and when it can be executed
     */

    function changeVotingRules(Token sharesAddress, uint minimumSharesToPassAVote, uint minutesForDebate) onlyOwner public {
        sharesTokenAddress = Token(sharesAddress);
        if (minimumSharesToPassAVote == 0 ) minimumSharesToPassAVote = 1;
        minimumQuorum = minimumSharesToPassAVote;
        debatingPeriodInMinutes = minutesForDebate;
        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, sharesTokenAddress);
    }

    /**
     * Proposal to remove
     * Propose to remove oracle
     * @param _remove is the oracle address to remove
     */
    function newProposal(string _description) onlyShareholders public returns (uint proposalID) {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.remove = _remove
        p.minExecutionDate = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numProposals = proposalID+1;
        return proposalID;
    }

    /**
     * Check if a proposal code matches
     *
     * @param proposalNumber ID number of the proposal to query
     * @param transactionBytecode bytecode of transaction
     */
    function checkProposalCode(uint proposalNumber,bytes transactionBytecode) constant public returns (bool codeChecksOut){
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(description, transactionBytecode);
    }

    /**
     * Log a vote for a proposal
     *
     * Vote `supportsProposal? in support of : against` proposal #`proposalNumber`
     *
     * @param proposalNumber number of proposal
     * @param supportsProposal either in favor or against it
     */
    function vote(uint proposalNumber, bool supportsProposal) onlyShareholders public returns (uint voteID) {
        Proposal storage p = proposals[proposalNumber];
        require(p.voted[msg.sender] != true);

        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = voteID +1;
        Voted(proposalNumber,  supportsProposal, msg.sender);
        return voteID;
    }

    /**
     * Finish vote
     *
     * Count the votes proposal #`proposalNumber` and execute it if approved
     *
     * @param proposalNumber proposal number
     * @param transactionBytecode optional: if the transaction contained a bytecode, you need to send it
     */
    function executeProposal(uint proposalNumber, bytes transactionBytecode) public {
        Proposal storage p = proposals[proposalNumber];

        require(now > p.minExecutionDate                                             // If it is past the voting deadline
            && !p.executed                                                          // and it has not already been executed
            && p.proposalHash == keccak256(p.recipient, p.amount, transactionBytecode)); // and the supplied code matches the proposal...


        // ...then tally the results
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;

        for (uint i = 0; i <  p.votes.length; ++i) {
            Vote storage v = p.votes[i];
            uint voteWeight = sharesTokenAddress.balanceOf(v.voter);
            quorum += voteWeight;
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }

        require(quorum >= minimumQuorum); // Check if a minimum quorum has been reached

        if (yea > nay ) {
            // Proposal passed; execute the transaction

            p.executed = true;
            require(p.recipient.call.value(p.amount)(transactionBytecode));

            p.proposalPassed = true;
        } else {
            // Proposal failed
            p.proposalPassed = false;
        }

        // Fire Events
        ProposalTallied(proposalNumber, yea - nay, quorum, p.proposalPassed);
    }
}

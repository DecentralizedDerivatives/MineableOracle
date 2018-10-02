# Proof of Work Oracle (PoWO)

<b>Proof of Work Oracle (PoWO)</b> is a decentralized oracle governed by the PoWO token holders. It provides a decentralized alternative for contracts to interact with and obtain data from offchain. 

The PoWO implements a mineable proof-of-work (PoW) where miners, along with the PoW solution also provide an offchain data point.  Once validated and processed the value is available for on-chain contracts to use.

![Header Image](./public/PowoFlow.png)

## Overview

**Contracts Description**
* <b>OracleToken.sol</b> -- is the Oracle contract. It allows miners to submit the proof of work and value, sorts the values, uses functions from ProofOfWorkToken to pay the miners, allows the data users to "tip" the miners for providing a value for a specific timestamp and allows the users to retreive the values.

* <b>OracleVote.sol</b> -- contains the voting mechanism for adding or changing oracles(uses balance checkpoints to avoid double voting), minting, paying the the miners, ERC20 token functionallity, and cloning process for efficiently deploying new oracles. Oracle vote is ProofOfWorkToken.sol and ProofOfWorkToken.sol is CloneFactory.sol and Token.sol.

    * <b>ProofOfWorkToken.sol</b> -- contains all the fucntionallity to set an origin(dud) oracle, deploy new oracles, remove oracles, and pay the miners. 

    * <b>CloneFactory.sol</b> -- allows ProofOfWorkToken to create and deploy an oracle efficiently. It creates a "clone" the dud oracle. The dud oracle acts as a byte code library for all the oracle contracts deployed based on it. To over simplify it is similar to how contracts reference the SafeMath library. Checkout our article, [Attack Of The Clones-How DDA Contracts Are So Cheap To Deploy](https://blog.goodaudience.com/attack-of-the-clones-how-dda-contracts-are-so-cheap-to-deploy-f3cee9c7566)

    * <b>Token.sol</b> -- contains all the ERC20 token functionallity for the PoWO Token

Note: There is no owner for the OracleToken.sol or OracleVote.sol, these are are managed and governed by the POWO token owners.  


### Instructions for quick start with Truffle Deployment 

Follow the steps below to launch the Oracle contracts using Truffle. 

Clone the repo, cd into it, and then:

    $ npm install

    $ truffle compile

    $ truffle migrate

    $ truffle exec scripts/DeployOracleandOracleVote.js


This project draws high-level inspiration from the [EIP918 Mineable Token](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md) as an abstract standard that uses a challenge-driven keccak256 Proof of Work algorithm for token minting and distribution.  

POWO leverages a proven game-theoretical competition to disintermediate and decentralize the existing 3rd party trust layer associated with centralized oracle services like Oraclize, which use basic API getters to provide smart-contracts with off-chain data.  This reduces the implicit cost of risk associated with third parties.  For more information, see:

> "Trusted third parites are security holes" ~ Nick Szabo, 2001 (https://nakamotoinstitute.org/trusted-third-parties/)

To summarize, by creating an oracle schema that uses an incented construct to derive the validity of off-chain data, we:
  1. <b>Reduce the risks</b> associated with single-party oracle providers, who can cut access to API data, forge message data, etc
  2. <b>Lay the foundation</b> for a superior oracle system where truth data is derived from a distributed set of participants which have both economic interest and 'stake' in the validity and success of the oracle data
  3. <b>Create</b> an effective, secure, and incentivized system for off-chain data which ingests inputs from five random parties(miners) and disincentives dispersion and adversarial submissions


## How It Works

<b>Overview</b> :(https://medium.com/@nfett/proof-of-work-oracle-6de6f795d27)

Users engage in a POW competition to find a nonce which satisfies the requirement of the challenge.  The first five users who solve the POW puzzle input data for the POW Oracle contract and receive native tokens in exchange for their work.  The oracle data submissions are stored in contract memory as an array - which is subsequently operated upon to derive the median value. 

Each input value is expressed as an integer with a timestamp describing the point in time that the oracle truth corresponds to.  On average, these oracle truths are mined and recorded at an interval dynamically adjusted to correspond to the total work inputted - so that truthpoints (represented as values stored for P sub n variables) may be expressed in a timeseries array fed into another contract, or visualized in a front-end through an event (see UX section for an example).

To ensure scalability and maximize usage potential, the smart-contract has been designed ground-up using the principle of 'gas-minimization'.  The contract is currently deployed on the Rinkeby Ethereum testnet. We encourage testing, security auditing, and UX critiques.


### The Oracle Mining Process
The current challenge, adjusted difficulty, count, and proof since last timestamp are all called during the 'proofOfWork' operation.

As explained in the initial section, the PoW Oracle uses a native token as a reward for miners who solve the POW challenge and subsequently input data for the contract.  This token inherets from the ERC-20 contract standard for fungible tokens, as may be seen in the 'contracts' hierarchy.

The mining process is formally expressed as:

```solidity
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
```

An implementation of the miner is descrbed in python in the 'miner' sub directory.  In 'miner.py', the script imports the web3 library, pandas, and various other dependencies to solve the keccak256 puzzle.  In submitter.js, the nonce value inputs are submitted to the smart contract on chain.  To examine the mining script, navigate [here](https://github.com/DecentralizedDerivatives/MineableOracle/miner/miner.py).


### Reward Incentives in POWO
The Reward schema is an essential component of MOC.  The schema is designed to incentivize miners to input <i>valid</i> truthpoints - as outlying datapoints in the sample receive proportionally less reward than the median input.

This Reward schema is expressed in the contract, here:

```solidity
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
```

It may be visualized as so:

![Reward Mechanism](./RewardMechanism.PNG)


## Example Usage Scenarios

Within the context of Ethereum, oracles can be thought of as authoritative sources of off-chain data. These data points allow smart contracts to receive and condition executional instructions using extrinsic information.  This is highly useful for a wide-array of derivitive scenarios.

As PoWO is a contract mechanism that allows oracle data to be derived in a comeptitive, decentralized manner - we envision a wide array of use cases for this product.  Namely:
1. <b>Exchange-rate data:</b> interval based exchange-rate truthpoints may be used to create trustless financial derivatives
2. <b>Weather data logs:</b> for example, we may calculate insurance premium calculation based on a weather forecast
3. <b>Static/pseudo-static data:</b> logging and indexing various identifiers, country codes, currency codes
4. <b>Prediction Market Probability/Odds:</b> i.e. "What is the likelyhood that X event will happen"
5. <b>Prediction Market Resolution:</b> i.e. determining who won the most recent presidential election or sporting event
6. <b>Damage verification:</b> What were the net total results in damage for insurance contracts
7. <b>Pseudorandom number generation:</b> to select a winner in a distributed-lottery smart contract, etc.


## Conclusion

This project was originally a submission to <b>Angel Hack's Washington DC Hackathon</b> hosted on July 7th - 8th, 2018.  It has since been taken over by DDA. 

<i>We invite you</i> to audit and test our project - and submit any issues to the repo directly.


#### Contributors

Nicholas Fett (nfett@decentralizedderivatives.org), Kevin Leffew (kleffew94@gmail.com), Sam Everett (severett29@gmail.com), Brenda Loya (bloya@decentralizedderivatives.org), Lucian Stroie (luciandstroie@gmail.com)


#### Copyright

DDA Inc. 2018

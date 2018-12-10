<p align="center">
  <a href='https://www.daxia.us/'>
    <img src= './public/DarkText_IconColor.png' width="300" height="100" alt='Daxia.us' />
  </a>
</p>

<p align="center">
  <a href='https://dapp.daxia.us/'>
    <img src= ./public/DApp-Daxia-blue.svg alt='Slack' />
  </a>
  <a href='https://deriveth.slack.com/'>
    <img src= ./public/Chat-Slack-blue.svg alt='Slack' />
  </a>
  <a href='https://t.me/daxiachat'>
    <img src= ./public/Chat-Telegram-blue.svg alt='Telegram DaxiaChat' />
  </a>
  <a href='https://twitter.com/DaxiaOfficial'>
    <img src= 'https://img.shields.io/twitter/url/http/shields.io.svg?style=social' alt='Twitter DaxiaOfficial' />
  </a> 
  <img src= ./public/License-MIT-blue.svg alt='MIT License' /> 
</p>

    
## Table of Contents

   * [How Does it work?](#how-it-works)
   * [The Oracle Mining Process](#mining-process)
   * [Example Usage Scenarios](#usage-scenarios)
   * [Conclusion](#Conclusion)
   * [Updates](#Updates)

<details><summary>Contributing information</summary>

   * [Maintainers](#Maintainers)
   * [How to Contribute](#how2contribute)
   * [Copyright](#copyright)
 </details>



### How Does it work? <a name="how-it-works"> </a>

Once a dud (origin) oracle contract is voted on and deployed, the new proposed oracles are "cloned" from the dud oracle (i.e. they use the dud oracle as a bytes library). All new proposals for new oracles specify the type of data (e.g. an API) to be submitted along with the PoW. The difficulty for the PoW is adjusted to target 10 minutes. Similar to the way Ethereum rewards ‘Uncles’ or miners who were close to winning, the first five miners to submit a PoW and off-chain value are awarded the native PoWO token. The miner that submits the median value is awarded a larger quantity of the total payoff. The payout structure can be specified when proposing a new oracle. 

Proof Of Work Oracle Reward Mechanism  

<div style="text-align:center">

![Reward Mechanism](./public/RewardMechanism.PNG)
</div>

The current incentive structure leverages game-theory to disincentivize dispersion and adversarial submissions.

Once the median value is selected, it is stored, and a new challenge is created. The median value is selected efficiently via an insert sort in the pushValue function used within the OracleToken contract proofOfWork function:

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

As miners submit the PoW and off-chain value, the value is sorted and as soon as five values are received, the median value (integer) and the timestamp (Unix timestamp) are saved to create an on-chain timeseries.

Miners are rewarded with PoWo tokens. PoWO tokens are charged for on-chain reads. This gives each token value, and more importantly, the value goes up as more smart contracts use our Oracle, thus creating a stronger incentive for miners.

Additionally, users can incentivize miners by posting a bounty via the addToValuePool function to ensure the next timestamp is mined. This function basically allows users to tip the miners.

#### The Oracle Mining Process <a name="mining-process"> </a>
The current challenge, adjusted difficulty, count, and proof since last timestamp are all called during the 'proofOfWork' operation/function. The PoW, is basically guessing a nonce that produces a hash with a certain number of leading zeros. The PoW challenge is chosen at random from the three challenges included in the proofOfWork function.  Miners can submit the PoW and the off-chain value using the function proofOfwork in OracleToken.sol. 


The mining process is formally expressed as:

```solidity
    function proofOfWork(string nonce, uint value) external returns (uint256,uint256) {
        bytes32 _solution = keccak256(abi.encodePacked(currentChallenge,msg.sender,nonce)); // generate random hash based on input
        uint _rem = uint(_solution) % 3;
        bytes32 n;
        if(_rem == 2){
            n = keccak256(abi.encodePacked(_solution));
        }
        else if(_rem ==1){
            n = sha256(abi.encodePacked(_solution));
        }
        else{
            n = keccak256(abi.encodePacked(ripemd160(abi.encodePacked(_solution))));
        }

        require(uint(n) % difficulty == 0 && value > 0 && miners[currentChallenge][msg.sender] == false); //can we say > 0? I like it forces them to enter a valueS  
        first_five[count].value = value;
        first_five[count].miner = msg.sender;
        count++;
        miners[currentChallenge][msg.sender] = true;
        uint _payoutMultiplier = 1;
        emit NonceSubmitted(msg.sender,nonce,value);
        if(count == 5) { 
            if (now - timeOfLastProof < (timeTarget *60)/100){
                difficulty++;
            }
            else if (now - timeOfLastProof > timeTarget && difficulty > 1){
                difficulty--;
            }
            
            uint i = (now - (now % timeTarget) - timeOfLastProof) / timeTarget;
            timeOfLastProof = now - (now % timeTarget);
            uint valuePool;
            while(i > 0){
                valuePool += payoutPool[timeOfLastProof - (i - 1) * timeTarget];
                i = i - 1;
            }
            if(valuePool >= payoutTotal) {
                _payoutMultiplier = (valuePool + payoutTotal) / payoutTotal; //solidity should always round down
                payoutPool[timeOfLastProof] = valuePool % payoutTotal;
            }
            else{
                payoutPool[timeOfLastProof] = valuePool;
            }
            pushValue(timeOfLastProof,_payoutMultiplier);
            count = 0;
            currentChallenge = keccak256(abi.encodePacked(nonce, currentChallenge, blockhash(block.number - 1))); // Save hash for next proof
         }
     return (count,timeOfLastProof); 
    }
```

An implementation of the miner is described in python in the 'miner' sub directory.  In 'miner.py', the script imports the web3 library, pandas, and various other dependencies to solve the keccak256 puzzle.  In submitter.js, the nonce value inputs are submitted to the smart contract on-chain.  To examine the mining script, navigate [here](./miner/).


## Example Usage Scenarios <a name="usage-scenarios"> </a>

Within the context of Ethereum, oracles can be thought of as authoritative sources of off-chain data. These data points allow smart contracts to receive and condition executional instructions using extrinsic information.  This is highly useful for a wide-array of derivitive scenarios.

As PoWO is a contract mechanism that allows oracle data to be derived in a comeptitive, decentralized manner - we envision a wide array of use cases for this product.  Namely:
1. <b>Exchange-rate data:</b> interval based exchange-rate truthpoints may be used to create trustless financial derivatives
2. <b>Weather data logs:</b> for example, we may calculate insurance premium calculation based on a weather forecast
3. <b>Static/pseudo-static data:</b> logging and indexing various identifiers, country codes, currency codes
4. <b>Prediction Market Probability/Odds:</b> i.e. "What is the likelihood that X event will happen"
5. <b>Prediction Market Resolution:</b> i.e. determining who won the most recent presidential election or sporting event
6. <b>Damage verification:</b> What were the net total results in damage for insurance contracts
7. <b>Pseudorandom number generation:</b> to select a winner in a distributed-lottery smart contract, etc.


## Conclusion <a name="conclusion"> </a>
The PoWO provides a decentralized option for off-chain data. We realize the short comming of PoW but as of now it has proven to work and we are providing users a way to move away from it once a better option comes along.  

By creating an oracle schema that uses an incented construct to derive the validity of off-chain data, we:
* <b>Reduce the risks</b> associated with single-party oracle providers, who can cut access to API data, forge message data, etc
* <b>Lay the foundation</b> for a superior oracle system where data is derived from a distributed set of participants which have both economic interest and 'stake' in the validity and success of the oracle data
* <b>Create</b> an effective, secure, and incentivized system for off-chain data which ingests inputs from five random parties(miners) and disincentives dispersion and adversarial submissions 

#### Maintainers <a name="maintainers"> </a> 
[@themandalore](https://github.com/themandalore)
<br>
[@brendaloya](https://github.com/brendaloya) 


#### How to Contribute<a name="how2contribute"> </a>  
Join our slack, shoot us an email or contact us: [<img src="./public/slack.png" width="24" height="24">](https://deriveth.slack.com/)
[<img src="./public/telegram.png" width="24" height="24">](https://t.me/ddaorg)
[<img src="./public/discord.png" width="24" height="24">](https://discordapp.com/invite/xtsdpbS)

Check out or issues log here on Github or contribute to our future plans to implement a GPU miner(not built in python), provide a way to pay in Ether for data, and improve our reward/incentives mechanism. 

Any contributions are welcome!

#### Copyright

DDA Inc. 2018
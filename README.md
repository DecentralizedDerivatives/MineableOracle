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

* [Instructions for quick start with Truffle Deployment](#Quick-Deployment)
   * [Detailed documentation for self setup](./SetupDocumentation.md)
* [Overview](#overview)
    * [In-Depth Overview](./InDepthOverview.md)

<details><summary>Contributing information</summary>

   * [Maintainers](#Maintainers)
   * [How to Contribute](#how2contribute)
   * [Copyright](#copyright)
 </details>

# Daxia's Proof of Work Oracle (PoWO)


### Instructions for quick start with Truffle Deployment <a name="Quick-Deployment"> </a> 
Follow the steps below to launch the Oracle contracts using Truffle. 

Open terminal:
    Clone the repo, cd into it, and then run:

    $ npm install

    $ truffle compile

    $ truffle migrate

    $ truffle exec scripts/01_DeployAndSetDudOracleAndTwoOracles.js

##### Testing

1. Open a second terminal and run:
   $ ganache-cli -m "nick lucian brenda kevin sam fiscal patch fly damp ocean produce wish"

2. On main terminal run: 
```solidity
    $   truffle test
```
3. And wait for the message 'START MINING RIG!!'

4. Kick off the python miner file [./miner/testMinerB.py](./miner/testMinerB.py).


Production and test python miners are available under the miner subdirectory [here](./miner/). You will need to get at least 5 miners running.

Step by step instructions on setting up a Mineable Oracle without truffle are available here: [Detailed documentation for self setup](./SetupDocumentation.md)


## Overview <a name="overview"> </a>  
Ethereum smart contracts cannot access off-chain data. If your smart contract relies on off-chain (e.g. internet) data to evaluate or execute a function, you either have to manually feed the data to your contract, incentivize users to do it, or rely on a centralized party to provide the data (Oraclize.it is generally the standard). 

<b>Proof of Work Oracle (PoWO)</b> is a decentralized oracle. It provides a decentralized alternative for contracts to interact with and obtain data from off-chain. 

The PoWO implements a mineable proof-of-work (PoW) where miners, along with the PoW solution also provide an off-chain data point. The first five miners to provide the PoW and off-chain data point are rewarded: the miner with the median value is given the highest reward since that is what is used as the 'offical' value and the four miners get a lower reward that decreases the further they are from the median. Once validated and processed the value is available for on-chain contracts to use.

We have implemented PoW because it is reliable, <b>now</b>. However, once Proof of Stake (PoS) is proven Daxia can decide to switch from PoW to Proof of Stake (PoS).

<p align="center">
<img src="./public/Powo.png" width="400" height="200" alt = "How it works">
</p>

A deep dive in methododology is available here: [In-Depth Overview](./InDepthOverview.md)

For a quick overview checkout our article, [Proof-of-Work Oracle](https://medium.com/@nfett/proof-of-work-oracle-6de6f795d27).  

### Useful links <a name="useful-links"> </a>
High level inspiration from [EIP918 Mineable Token](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-918.md).

Why we need a decentralized option? Checkout: ["Trusted third parites are security holes" ~ Nick Szabo, 2001](https://nakamotoinstitute.org/trusted-third-parties/)

Metamask - www.metamask.io 

Truffle - http://truffleframework.com/

If you have questions, ask us on Slack: https://deriveth.slack.com/

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

### Updates <a name="updates"> </a>
We are happy to report that a successful PoWO build has successfully compiled and been deployed to the Rinkeby testnet. 

July 8, 2018--this project was a submission to <b>Angel Hack's Washington DC Hackathon</b> hosted on July 7th - 8th.  It was designed, spec'ed, built, and deployed in a 24-hour agile sprint.

September 30, 2018--This project has been revised to improve efficiency.

December 10, 2018 -- This project has been revised to improve security. 

<i>We invite you</i> to audit and test our project - and submit any issues to the repo directly.

#### Contributors<a name="contributors"> </a>

Nicholas Fett (nfett@daxia.us), Kevin Leffew (kleffew94@gmail.com), Sam Everett (severett29@gmail.com), Brenda Loya (bloya@daxia.us), Lucian Stroie (luciandstroie@gmail.com)


#### Copyright

DDA Inc. 2018

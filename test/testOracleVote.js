/** This contract tests the typical workflow from the dApp 
* (user contract, cash out)
*/
var oracleToken = artifacts.require("OracleToken");
var oracleVote = artifacts.require("OracleVote");
var Token = artifacts.require("Token");
var POWT = artifacts.require("ProofOfWorkToken.sol");
var CloneFactory = artifacts.require("CloneFactory.sol");

contract('Base Tests', function(accounts) {
  let oracletoken;
  let oraclevote;
  let token;
  let powt;
  let clonefactory;
  
    beforeEach('Setup contract for each test', async function () {
        oracletoken = await oracleToken.new();
        console.log(oracletoken.address);
        oraclevote = await oracleVote.new();
        console.log(oraclevote.address);
        await oraclevote.setProposalFee(22);
        console.log("setproposal");
        token = await Token.new();
        console.log(token.address);
        clonefactory = await CloneFactory.new();
        console.log(clonefactory.address);
/*      powt = await POWT.new();//dudd
        console.log(powt.address);
        await powt.setDudOracle(powt.address);
        console.log("dud", await powt.dud_Oracle.call());
        await powt.deployNewOracle("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,5,[1,5,10,5,1]);
        console.log(powt.address);
        res = res.logs[0].args._ProofOfWorkToken;
        powt = await powt.at(res);*/
        //transfer powo to other accts so they can vote and propose
        await token.transferFrom(accounts[0], accounts[4],100,{from:accounts[0]});
        console.log("transfer successful acct4");
        await token.transferFrom(accounts[0], accounts[5],100,{from:accounts[0]});
        console.log("transfer successful acct5");
        await token.transferFrom(accounts[0], accounts[6],100,{from:accounts[0]});
        console.log("transfer successful acct6");
        await token.transferFrom(accounts[0], accounts[7],100,{from:accounts[0]});
        console.log("transfer successful acct7");

    });

    it("Change quorum and voting timeframe", async function(){
        await oraclevote.changeVotingRules(2, 3);
        quorum = await oraclevote.minimumQuorum.call();
        console.log(quorum);
        assert.equal(quorum,2, "minimumQuorum fee is now 2");
        duration = await oraclevote.voteDuration.call();
        console.log(duration);
        assert.equal(duration,3, "voteDuration is 3 days");
    });

    it("Change proposal fee", async function(){
        await oraclevote.setProposalFee(26);
        propFee = await oraclevote.proposalFee.call();
        console.log(propFee);
        assert.equal(propFee,26, "Proposal fee is now 26");
    });

    it("Number of proposals", async function(){
        oracletoken2 = await oracleToken.new();
        count = await oraclevote.countProposals();
        assert.equal(count, 0);
        //await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        //assert.equal(count, 1);
        //await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,5,[1,5,10,5,1], {from:accounts[5]});
        //assert.equal(count, 2);
     });

    it("Proposal to remove, vote, tally", async function(){
        balance4 = await (token.balanceOf(accounts[4],{from:accounts[0]}));
        console.log(balance4);
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        balance4a = await (token.balanceOf(accounts[4],{from:accounts[0]}));
        console.log(balance4a);
        //assert(balance4>balance4a, "initial balance should be lower");
        //await oraclevote.vote(1, true,{from:accounts[0]} );
        //await oraclevote.vote(1, true,{from:accounts[4]} );
        //await oraclevote.vote(1, true,{from:accounts[5]} );
        //await oraclevote.vote(1, true,{from:accounts[6]} );
        //await oraclevote.vote(1, false,{from:accounts[7]} );
        //await oraclevote.vote(1, false,{from:accounts[8]} );
        //await oraclevote.tallyVotes(1, {from:accounts[1]});
        //info = await oraclevote.getProposalInfo(1);
        //assert( info = [1, true], "proposal passed")

    });

    it("Proposal to add, vote, tally", async function(){
        balance5 = await (token.balanceOf(accounts[5],{from:accounts[0]}));
        console.log(balance5);
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,5,[1,5,10,5,1], {from:accounts[5]});
        balance5a = await (token.balanceOf(accounts[5],{from:accounts[0]}));
        console.log(balance5a);
         //await oraclevote.vote(1, false,{from:accounts[0]} );
        //await oraclevote.vote(1, true,{from:accounts[4]} );
        //await oraclevote.vote(1, true,{from:accounts[5]} );
        //await oraclevote.vote(1, false,{from:accounts[6]} );
        //await oraclevote.vote(1, false,{from:accounts[7]} );
        //await oraclevote.vote(1, false,{from:accounts[8]} );
        //await oraclevote.tallyVotes(1, {from:accounts[1]});
        //info = await oraclevote.getProposalInfo(1);
        //assert( info = [2, false], "proposal failed")
    });


    it("Should allow owner to change contract owner", async function () {
        await oraclevote.setOwner(accounts[5], {from: accounts[0]});
        assert(oraclevote.owner = accounts[5], "owner should be account 5");
        await oraclevote.setOwner(accounts[0], {from: accounts[5]});
    });



});

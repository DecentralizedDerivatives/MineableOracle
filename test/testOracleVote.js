/** This contract tests the oracleVote.sol functions
*/
var oracleToken = artifacts.require("OracleToken");
var oracleVote = artifacts.require("OracleVote");
var Token = artifacts.require("Token");
var POWT = artifacts.require("ProofOfWorkToken.sol");
var CloneFactory = artifacts.require("CloneFactory.sol");

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

contract('Base Tests', function(accounts) {
  let oracletoken;
  let oraclevote;
  let token;
  let powt;
  let clonefactory;
  
    beforeEach('Setup contract for each test', async function () {
        oracletoken = await oracleToken.new();
        console.log("dud oracle:", oracletoken.address);
        oraclevote = await oracleVote.new();
        console.log("oracle vote:", oraclevote.address);
        await oraclevote.setProposalFee(22);
        console.log("set proposal fee");
        await oraclevote.setDudOracle(oracletoken.address);
        console.log("setDudOracle", await oraclevote.dud_Oracle.call());
        balance0 = await (oraclevote.balanceOf(accounts[0],{from:accounts[0]}));
        console.log("owner bal", balance0);
        await oraclevote.transfer(accounts[4],100,{from:accounts[0]});
        console.log("transfer successful acct4");
        await oraclevote.transfer(accounts[5],100,{from:accounts[0]});
        console.log("transfer successful acct5");
        await oraclevote.transfer(accounts[6],100,{from:accounts[0]});
        console.log("transfer successful acct6");
        await oraclevote.transfer(accounts[7],100,{from:accounts[0]});
        console.log("transfer successful acct7");

        let res = await oraclevote.deployNewOracle("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,10,[1,5,10,5,1]); 
        res = res.logs[0].args._newOracle;
        oracletoken = await oracleToken.at(res);
        console.log("cloned oracle res",res); 
        console.log("oracle.address:", oracletoken.address); 

        let res2 = await oraclevote.deployNewOracle("json(https://api.gdax.com/products/ETH-USD/ticker).price",22,10,[1,5,10,5,1]); 
        res2 = res2.logs[0].args._newOracle;
        oracletoken2 = await oracleToken.at(res2);
        console.log("cloned oracle res2",res2); 
        console.log("oracle.address2:", oracletoken2.address); 
    });

    it("Change quorum and voting timeframe", async function(){
        await oraclevote.changeVotingRules(2, 3);
        quorum = await oraclevote.minimumQuorum.call();
        console.log(quorum);
        assert.equal(quorum,2, "minimumQuorum is now 2");
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
        count = await oraclevote.countProposals();
        assert.equal(count, 0);
        console.log("count", count);
        balance4 = await oraclevote.balanceOf(accounts[4],{from:accounts[0]});
        console.log("balance 4a:",  balance4);
        await oraclevote.changeVotingRules(2, 3);
        await oraclevote.getProposalsIds();
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        console.log("prop array:", await oraclevote.getProposalsIds());
        count2 = await oraclevote.countProposals();
        assert.equal(count2, 1);
        console.log("count 2:", count2);
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,5,[1,5,10,5,1], {from:accounts[5]});
        count3 = await oraclevote.countProposals();
        console.log("count 3:", count3);
        assert.equal(count3, 2);
     });

    it("Remove Oracle", async function(){
        console.log("get details2", await oraclevote.getDetails(oracletoken2.address));
        console.log("get index oracle 2", await oraclevote.getindex(oracletoken2.address));
        console.log("get index oracle1", await oraclevote.getindex(oracletoken.address));
        console.log("get details1", await oraclevote.getDetails(oracletoken.address));
        await oraclevote.removeOracle(oracletoken.address);
        console.log("get index oracle1-remove", await oraclevote.getindex(oracletoken.address));
        details = await oraclevote.getDetails(oracletoken.address);
        assert(details = [ '', '0x0000000000000000000000000000000000000000' ], "oracle removed")
    });

    it("Add Oracle", async function(){
        let res3 = await oraclevote.deployNewOracle("json(https://api.gdax.com/products/ETH-USD/ticker).price",22,10,[1,5,10,5,1]); 
        res3 = res3.logs[0].args._newOracle;
        oracletoken3 = await oracleToken.at(res3);
        console.log("cloned oracle res3",res3); 
        console.log("oracle.address3:", oracletoken3.address); 
    });

    it("Proposal to remove, vote, tally", async function(){
        await oraclevote.changeVotingRules(1, 1);
        balance4 = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        console.log("initial bal:",balance4);
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        count = await oraclevote.countProposals();
        //assert.equal(count, 1);
        console.log("count", count);
        balance4a = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        console.log("end bal:",balance4a);
        assert(balance4 - balance4a == 22, "initial balance should be lower");
        console.log("get details2", await oraclevote.getDetails(oracletoken2.address));
        console.log("get index oracle 2", await oraclevote.getindex(oracletoken2.address));


        await oraclevote.vote(1, true,{from:accounts[0]} );
        await oraclevote.vote(1, true,{from:accounts[4]} );
  /*      await oraclevote.vote(1, true,{from:accounts[5]} );
        await oraclevote.vote(1, true,{from:accounts[6]} );
        await oraclevote.vote(1, false,{from:accounts[7]} );
        info = await oraclevote.getProposalInfo(1);
        console.log("info:", info);*/
        //sleep_s(3);
        await oraclevote.tallyVotes(1, {from:accounts[4]} );
/*        info1 = await oraclevote.getProposalInfo(1);
        console.log("info1:", info1);
        assert( info1 = [1, true], "proposal passed")*/
        console.log("get index oracle1-remove", await oraclevote.getindex(oracletoken2.address));
        console.log("get details1 remove", await oraclevote.getDetails(oracletoken2.address));
    });

/*    it("Proposal to add, vote, tally", async function(){
        balance5 = await (powt.balanceOf(accounts[5],{from:accounts[0]}));
        console.log(balance5);
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,5,[1,5,10,5,1], {from:accounts[5]});
        balance5a = await (powt.balanceOf(accounts[5],{from:accounts[0]}));
        console.log(balance5a);*/
         //await oraclevote.vote(1, false,{from:accounts[0]} );
        //await oraclevote.vote(1, true,{from:accounts[4]} );
        //await oraclevote.vote(1, true,{from:accounts[5]} );
        //await oraclevote.vote(1, false,{from:accounts[6]} );
        //await oraclevote.vote(1, false,{from:accounts[7]} );
        //await oraclevote.vote(1, false,{from:accounts[8]} );
        //await oraclevote.tallyVotes(1, {from:accounts[1]});
        //info = await oraclevote.getProposalInfo(1);
        //assert( info = [2, false], "proposal failed")
/*    });*/


/*    it("Should allow owner to change contract owner", async function () {
        await oraclevote.setOwner(accounts[5], {from: accounts[0]});
        assert(oraclevote.owner = accounts[5], "owner should be account 5");
        await oraclevote.setOwner(accounts[0], {from: accounts[5]});
    });*/



});

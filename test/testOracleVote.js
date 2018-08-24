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
        oraclevote = await oracleVote.new(22,1,1);
        console.log("oracle vote:", oraclevote.address);
        await oraclevote.propDudOracle(oracletoken.address);
        await oraclevote.vote(1, true,{from:accounts[0]} );
        await oraclevote.tallyVotes(1, {from:accounts[0]} )

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
        await oraclevote.transfer(accounts[8],100,{from:accounts[0]});
        console.log("transfer acct8");

        await oraclevote.propAdd("testAddproposedOracle",22,5,[1,5,10,5,1], {from:accounts[8]});
        await oraclevote.vote(2, true,{from:accounts[0]} );
        let res = await oraclevote.tallyVotes(2, {from:accounts[0]} );
        res = res.logs[0].args._newOracle;
        console.log("res address", res);
        oracletoken = await oracleToken.at(res);

        await oraclevote.propAdd("testAddproposedOracle2",22,5,[1,5,10,5,1], {from:accounts[8]});
        await oraclevote.vote(3, true,{from:accounts[0]} );
        let res2 = await oraclevote.tallyVotes(3, {from:accounts[0]} );
        res2 = res2.logs[0].args._newOracle;
        oracletoken2 = await oracleToken.at(res2);

    });


     it("Number of proposals", async function(){
        count = await oraclevote.countProposals();
        assert.equal(count, 3);
        console.log("count", count);
        balance4 = await oraclevote.balanceOf(accounts[4],{from:accounts[0]});
        console.log("balance 4:",  balance4);
        await oraclevote.getProposalsIds();
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        console.log("prop array:", await oraclevote.getProposalsIds());
        count2 = await oraclevote.countProposals();
        assert.equal(count2, 4);
        console.log("count 2:", count2);
        balance4a = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        console.log("end bal:",balance4a);
        assert(balance4 - balance4a == 22, "initial balance should be lower");
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,5,[1,5,10,5,1], {from:accounts[5]});
        count3 = await oraclevote.countProposals();
        console.log("count 3:", count3);
        assert.equal(count3, 5);
     });


    it("Proposal to remove, vote, tally-Pass", async function(){
        balance4 = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        console.log("initial bal:",balance4);
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        console.log("count", count);
        balance4a = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        console.log("end bal:",balance4a);
        assert(balance4 - balance4a == 22, "initial balance should be lower");
        let initdetails = await oraclevote.getDetails(oracletoken2.address);
        assert (initdetails = ['json(https://api.gdax.com/products/ETH-USD/ticker).price', oracletoken2.address], "oracle to remove")
        await oraclevote.vote(4, true,{from:accounts[0]} );
        await oraclevote.vote(4, true,{from:accounts[4]} );
        await oraclevote.vote(4, true,{from:accounts[5]} );
        await oraclevote.vote(4, true,{from:accounts[6]} );
        await oraclevote.vote(4, false,{from:accounts[7]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );
        info1 = await oraclevote.getProposalInfo(4);
        console.log("info1:", info1);
        assert( info1 = [4, true], "proposal passed")
        details = await oraclevote.getDetails(oracletoken2.address);
        assert(details = [ '', '0x0000000000000000000000000000000000000000' ], "oracle removed")
    });

    it("Proposal to add, vote, tally-Pass", async function(){
        balance5 = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        console.log("initial bal:",balance5);
        await oraclevote.propAdd("testAddproposedOracle",22,5,[1,5,10,5,1], {from:accounts[5]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        console.log("count", count);
        balance5a = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        console.log("end bal:",balance5a);
        assert(balance5 - balance5a == 22, "initial balance should be lower");
        await oraclevote.vote(4, true,{from:accounts[0]} );
        await oraclevote.vote(4, true,{from:accounts[4]} );
        await oraclevote.vote(4, true,{from:accounts[5]} );
        await oraclevote.vote(4, true,{from:accounts[6]} );
        await oraclevote.vote(4, false,{from:accounts[7]} );
        let tally = await oraclevote.tallyVotes(4, {from:accounts[0]} );//event 13
        info1 = await oraclevote.getProposalInfo(4);
        console.log("info1:", info1);
        assert( info1 = [4, true], "proposal passed")
        tally = tally.logs[0].args._newOracle;
        console.log("cloned oracle added", tally);
        details = await oraclevote.getDetails(tally);
        console.log("details:", details);
        assert(details = [ 'testAddproposedOracle', tally], "oracle removed")
    });

    it("Proposal to remove, vote, tally-fail", async function(){
        balance4 = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        console.log("initial bal:",balance4);
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        console.log("count", count);
        balance4a = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        console.log("end bal:",balance4a);
        assert(balance4 - balance4a == 22, "initial balance should be lower");
        let initdetails = await oraclevote.getDetails(oracletoken2.address);
        assert (initdetails = ['json(https://api.gdax.com/products/ETH-USD/ticker).price', oracletoken2.address], "oracle to remove")
        await oraclevote.vote(4, false,{from:accounts[0]} );
        await oraclevote.vote(4, true,{from:accounts[4]} );
        await oraclevote.vote(4, true,{from:accounts[5]} );
        await oraclevote.vote(4, true,{from:accounts[6]} );
        await oraclevote.vote(4, true,{from:accounts[7]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );
        info1 = await oraclevote.getProposalInfo(4);
        console.log("info1:", info1);
        assert( info1 = [4, false], "proposal passed")
        details = await oraclevote.getDetails(oracletoken2.address);
        assert(details = ['json(https://api.gdax.com/products/ETH-USD/ticker).price', oracletoken2.address], "oracle should not have been removed")
    });

    it("Proposal to add, vote, tally-Fail", async function(){
        balance5 = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        console.log("initial bal:",balance5);
        await oraclevote.propAdd("testAddproposedOracle",22,5,[1,5,10,5,1], {from:accounts[5]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        console.log("count", count);
        balance5a = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        console.log("end bal:",balance5a);
        assert(balance5 - balance5a == 22, "initial balance should be lower");
        await oraclevote.vote(4, false,{from:accounts[0]} );
        await oraclevote.vote(4, true,{from:accounts[4]} );
        await oraclevote.vote(4, true,{from:accounts[5]} );
        await oraclevote.vote(4, true,{from:accounts[6]} );
        await oraclevote.vote(4, true,{from:accounts[7]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );//event 13
        info1 = await oraclevote.getProposalInfo(4);
        console.log("info1:", info1);
        assert( info1 = [4, false], "proposal failed")
    });


/*    it("Change quorum", async function(){
        
        quorum = await oraclevote.minimumQuorum.call();
        console.log(quorum);
        assert.equal(quorum,2, "minimumQuorum is now 2");
        duration = await oraclevote.voteDuration.call();
        console.log(duration);
        assert.equal(duration,3, "voteDuration is 3 days");
    });

    it("Change quorum and voting timeframe", async function(){
        
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
*/


});

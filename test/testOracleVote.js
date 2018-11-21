/** This contract tests the oracleVote.sol functions
*/
/*var oracleToken = artifacts.require("./OracleToken.sol");
var oracleVote = artifacts.require("./OracleVote.sol");


function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

contract('Oracle Vote Tests', function(accounts) {
  let oracletoken;
  let oraclevote;
  
    beforeEach('Setup contract for each test', async function () {
        oracletoken = await oracleToken.new(accounts[0],22,(86400/60)/6,[1,5,10,5,1]);
        oraclevote = await oracleVote.new(22,1,1);
        await oraclevote.propDudOracle(oracletoken.address);
        await oraclevote.vote(1, true,{from:accounts[0]} );
        await oraclevote.tallyVotes(1, {from:accounts[0]} )
        balance0 = await (oraclevote.balanceOf(accounts[0],{from:accounts[0]}));
        await oraclevote.transfer(accounts[4],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[5],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[6],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[7],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[8],100,{from:accounts[0]});-
        await oraclevote.propAdd("testAddproposedOracle",22,(86400/60)/6,[1,5,10,5,1], {from:accounts[8]});
        await oraclevote.vote(2, true,{from:accounts[0]} );
        let res = await oraclevote.tallyVotes(2, {from:accounts[0]} );
        res = res.logs[0].args._newOracle;
        oracletoken = await oracleToken.at(res);
        
        await oraclevote.propAdd("testAddproposedOracle2",22,(86400/60)/6,[1,5,10,5,1], {from:accounts[8]});
        await oraclevote.vote(3, true,{from:accounts[0]} );
        let res2 = await oraclevote.tallyVotes(3, {from:accounts[0]} );
        res2 = res2.logs[0].args._newOracle;
        oracletoken2 = await oracleToken.at(res2);

    });

     it("Number of proposals", async function(){
        count = await oraclevote.countProposals();
        assert.equal(count, 3);
        balance4 = await oraclevote.balanceOf(accounts[4],{from:accounts[0]});
        await oraclevote.getProposalsIds();
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        count2 = await oraclevote.countProposals();
        assert.equal(count2, 4);
        balance4a = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        assert(balance4 - balance4a == 22, "initial balance should be lower");
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,5,[1,5,10,5,1], {from:accounts[5]});
        count3 = await oraclevote.countProposals();
        assert.equal(count3, 5);
     });

    it("Proposal to remove, vote, tally-Pass", async function(){
        balance4 = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        balance4a = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
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
        assert( info1 = [4, true], "proposal passed")
        details = await oraclevote.getDetails(oracletoken2.address);
        assert(details = [ '', '0x0000000000000000000000000000000000000000' ], "oracle removed")
    });

    it("Proposal to add, vote, tally-Pass", async function(){
        balance5 = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        await oraclevote.propAdd("testAddproposedOracle",22,5,[1,5,10,5,1], {from:accounts[5]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        balance5a = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        assert(balance5 - balance5a == 22, "initial balance should be lower");
        await oraclevote.vote(4, true,{from:accounts[0]} );
        await oraclevote.vote(4, true,{from:accounts[4]} );
        await oraclevote.vote(4, true,{from:accounts[5]} );
        await oraclevote.vote(4, true,{from:accounts[6]} );
        await oraclevote.vote(4, false,{from:accounts[7]} );
        let tally = await oraclevote.tallyVotes(4, {from:accounts[0]} );//event 13
        info1 = await oraclevote.getProposalInfo(4);
        assert( info1 = [4, true], "proposal passed")
        tally = tally.logs[0].args._newOracle;
        details = await oraclevote.getDetails(tally);
        assert(details = [ 'testAddproposedOracle', tally], "oracle removed")
    });

    it("Proposal to remove, vote, tally-fail", async function(){
        balance4 = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
        await oraclevote.propRemove(oracletoken2.address, {from:accounts[4]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        balance4a = await (oraclevote.balanceOf(accounts[4],{from:accounts[0]}));
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
        assert( info1 = [4, false], "proposal passed")
        details = await oraclevote.getDetails(oracletoken2.address);
        assert(details = ['json(https://api.gdax.com/products/ETH-USD/ticker).price', oracletoken2.address], "oracle should not have been removed")
    });

    it("Proposal to add, vote, tally-Fail", async function(){
        balance5 = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        await oraclevote.propAdd("testAddproposedOracle",22,5,[1,5,10,5,1], {from:accounts[5]});
        count = await oraclevote.countProposals();
        assert.equal(count, 4);
        balance5a = await (oraclevote.balanceOf(accounts[5],{from:accounts[0]}));
        assert(balance5 - balance5a == 22, "initial balance should be lower");
        await oraclevote.vote(4, false,{from:accounts[0]} );
        await oraclevote.vote(4, true,{from:accounts[4]} );
        await oraclevote.vote(4, true,{from:accounts[5]} );
        await oraclevote.vote(4, true,{from:accounts[6]} );
        await oraclevote.vote(4, true,{from:accounts[7]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );//event 13
        info1 = await oraclevote.getProposalInfo(4);
        assert( info1 = [4, false], "proposal failed")
    });


    it("Change quorum", async function(){
        quorum = await oraclevote.minimumQuorum.call();
        assert.equal(quorum,1, "minimumQuorum is now 1");
        await oraclevote.propMinimumQuorum(2, {from:accounts[5]});
        await oraclevote.vote(4, false,{from:accounts[0]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );
        quorum1 = await oraclevote.minimumQuorum.call();
        assert.equal(quorum1,2, "quorum is 2 days");
    });

    it("Change voting timeframe", async function(){
        duration = await oraclevote.voteDuration.call();
        assert.equal(duration,1, "minimumQuorum is now 1");
        await oraclevote.propVoteDuration(2, {from:accounts[5]});
        await oraclevote.vote(4, true,{from:accounts[0]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );
        duration1 = await oraclevote.voteDuration.call();
        assert.equal(duration1,2, "voteDuration is 2 days");        
    });

    it("Change proposal fee", async function(){
        propFee = await oraclevote.proposalFee.call();
        assert.equal(propFee,22, "propFee is 22");
        await oraclevote.propProposalFee(26, {from:accounts[5]});
        await oraclevote.vote(4, true,{from:accounts[0]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );
        propFee1 = await oraclevote.proposalFee.call();
        assert.equal(propFee1,26, "Proposal fee is now 26");
    });

    it("Change Dud Oracle", async function(){
        dudOracle = await oraclevote.dud_Oracle.call();
        //assert.equal(dudOracle,oracletoken.address, "oracle dud address");
        let oracletoken2 = await oracleToken.new(accounts[0],22,(86400/60)/6,[1,5,10,5,1]);
        await oraclevote.propDudOracle(oracletoken2.address, {from:accounts[5]});
        await oraclevote.vote(4, true,{from:accounts[0]} );
        await oraclevote.tallyVotes(4, {from:accounts[0]} );
        dudOracle1 = await oraclevote.dud_Oracle.call();
        assert.equal(dudOracle1,oracletoken2.address, "new oracle dudd address");
    });

    it("Get proposalsId list", async function(){
        proposalsList = await oraclevote.getProposalsIds();
        assert(proposalsList = [1,2,3], "proposals list");
    });
});
*/
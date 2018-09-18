/** This contract tests the ProofOfWorkToken functions
*/ 
var oracleToken = artifacts.require("./OracleToken.sol");
var oracleVote = artifacts.require("./OracleVote.sol");

contract('PoW Token Tests', function(accounts) {
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

    it("Token transfer", async function(){
        balance4 = await oraclevote.balanceOf(accounts[4]);
        await oraclevote.transfer(accounts[4],50,{from:accounts[6]});
        balance4a = await oraclevote.balanceOf(accounts[4]);
        balance6 = await oraclevote.balanceOf(accounts[6]);
        assert.equal(balance4a, 150, "balance for acct 4 is 150");
        assert.equal(balance6, 50, "balance for acct 6 is 50");
    });

    it("Approve and transferFrom", async function(){
        await oraclevote.approve(accounts[1], 500);
        balance0a = await (oraclevote.balanceOf(accounts[0],{from:accounts[1]}));
        await oraclevote.transferFrom(accounts[0], accounts[5], 500, {from:accounts[1]}); 
        balance5a = await (oraclevote.balanceOf(accounts[5]));
        assert.equal(balance5a, 600, "balance for acct 5 is 600");
    });

    it("Allowance after approve and transferFrom", async function(){
        await oraclevote.approve(accounts[1], 500);
        balance0a = await (oraclevote.balanceOf(accounts[0],{from:accounts[1]}));
        await oraclevote.transferFrom(accounts[0], accounts[5], 400, {from:accounts[1]}); 
        balance5a = await (oraclevote.balanceOf(accounts[5]));
        assert.equal(balance5a, 500, "balance for acct 5 is 600");
        allow = await oraclevote.allowance(accounts[0], accounts[1]);
        assert.equal(allow, 100, "Allowance shoudl be 100");
    });

    it("Total Supply", async function(){
        supply = await oraclevote.totalSupply();
        supply1 = supply.toNumber();
        contra = await oraclevote.balanceOf(oraclevote.address);
        contra1 = contra.toNumber();
        csupply = (2**256) - 1 - contra1;
        assert.equal(supply1,csupply,"Total Supply should be everything");
    });
});
 
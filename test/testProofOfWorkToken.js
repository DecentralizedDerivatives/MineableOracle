/** This contract tests the ProofOfWorkToken functions
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

    it("Token transfer", async function(){
        balance4 = await oraclevote.balanceOf(accounts[4]);
        console.log("old bal 4", balance4);
        await oraclevote.transfer(accounts[4],50,{from:accounts[6]});
        balance4a = await oraclevote.balanceOf(accounts[4]);
        console.log("new bal4", balance4a);
        console.log("transfer successful acct4");
        balance6 = await oraclevote.balanceOf(accounts[6]);
        console.log(balance6);
        assert.equal(balance4a, 150, "balance for acct 4 is 150");
        assert.equal(balance6, 50, "balance for acct 6 is 50");
    });

    it("Approve and transferFrom", async function(){
        await oraclevote.approve(accounts[1], 500);
        console.log("approve");
        balance0a = await (oraclevote.balanceOf(accounts[0],{from:accounts[1]}));
        console.log("old bal 0", balance0a);
        await oraclevote.transferFrom(accounts[0], accounts[5], 500, {from:accounts[1]}); 
        balance5a = await (oraclevote.balanceOf(accounts[5]));
        console.log("new bal5", balance5a);
        console.log("transfer successful acct5");
        assert.equal(balance5a, 600, "balance for acct 5 is 600");
    });

    it("Allowance after approve and transferFrom", async function(){
        await oraclevote.approve(accounts[1], 500);
        console.log("approve");
        balance0a = await (oraclevote.balanceOf(accounts[0],{from:accounts[1]}));
        console.log("old bal 0", balance0a);
        await oraclevote.transferFrom(accounts[0], accounts[5], 400, {from:accounts[1]}); 
        balance5a = await (oraclevote.balanceOf(accounts[5]));
        console.log("new bal5", balance5a);
        console.log("transfer successful acct5");
        assert.equal(balance5a, 500, "balance for acct 5 is 600");
        allow = await oraclevote.allowance(accounts[0], accounts[1]);
        console.log(allow);
        assert.equal(allow, 100, "Allowance shoudl be 100");
    });

    it("Total Supply", async function(){
        supply = await oraclevote.totalSupply();
        console.log("supply:", supply);
        supply1 = supply.toNumber();
        contra = await oraclevote.balanceOf(oraclevote.address);
        contra1 = contra.toNumber();
        console.log("contra1", contra1);
        csupply = (2**256) - 1 - contra1;
        console.log("circulating supply", csupply);
        //assert.equal(allow, 100, "Allowance shoudl be 100");
    });

    it("Total circulating supply", async function(){
        await oraclevote.approve(accounts[1], 500);
        console.log("approve");
        supply = await oraclevote.totalSupply();
        console.log("supply:", supply);
        supply1 = supply.toNumber();
        contra = await oraclevote.balanceOf(oraclevote.address);
        contra1 = contra.toNumber();
        console.log("contra1", contra1);
        csupply = (2**256) - 1 - contra1;
        console.log("circulating supply", csupply);
        //assert.equal(allow, 1000000, "Allowance shoudl be 100");
    });

});
 
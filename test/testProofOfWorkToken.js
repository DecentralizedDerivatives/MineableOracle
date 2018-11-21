/** This contract tests the ProofOfWorkToken functions
*/ 
var oracleToken = artifacts.require("./OracleToken.sol");
var proofOfWorkToken = artifacts.require("./ProofOfWorkToken.sol");

var timeframe = (86400); //Daily
var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';
var api2 = 'json(https://api.gdax.com/products/ETH-USD/ticker).price';

contract('PoW Token Tests', function(accounts) {
  let oracletoken;
  let proofofworktoken;
  let logNewValueWatcher;
    beforeEach('Setup contract for each test', async function () {
        oracletoken = await oracleToken.new(accounts[0],22,(86400/60)/6,[1,5,10,5,1]);
        proofofworktoken = await proofOfWorkToken.new();
        await proofofworktoken.setDudOracle(oracletoken.address);
        balance0 = await (proofofworktoken.balanceOf(accounts[0],{from:accounts[0]}));
        await proofofworktoken.transfer(accounts[4],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[5],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[6],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[7],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[8],100,{from:accounts[0]});
        let res = await proofofworktoken.deployNewOracle(api,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
        res = res.logs[0].args._newOracle;
        oracletoken = await oracleToken.at(res);   
        let res2 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
        res2 = res2.logs[0].args._newOracle;
        oracletoken2 = await oracleToken.at(res2); 
    });

    it("Token transfer", async function(){
        balance4 = await proofofworktoken.balanceOf(accounts[4]);
        await proofofworktoken.transfer(accounts[4],50,{from:accounts[6]});
        balance4a = await proofofworktoken.balanceOf(accounts[4]);
        balance6 = await proofofworktoken.balanceOf(accounts[6]);
        assert.equal(balance4a, 150, "balance for acct 4 is 150");
        assert.equal(balance6, 50, "balance for acct 6 is 50");
    });

    it("Approve and transferFrom", async function(){
        await proofofworktoken.approve(accounts[1], 500);
        balance0a = await (proofofworktoken.balanceOf(accounts[0],{from:accounts[1]}));
        await proofofworktoken.transferFrom(accounts[0], accounts[5], 500, {from:accounts[1]}); 
        balance5a = await (proofofworktoken.balanceOf(accounts[5]));
        assert.equal(balance5a, 600, "balance for acct 5 is 600");
    });

    it("Allowance after approve and transferFrom", async function(){
        await proofofworktoken.approve(accounts[1], 500);
        balance0a = await (proofofworktoken.balanceOf(accounts[0],{from:accounts[1]}));
        await proofofworktoken.transferFrom(accounts[0], accounts[5], 400, {from:accounts[1]}); 
        balance5a = await (proofofworktoken.balanceOf(accounts[5]));
        assert.equal(balance5a, 500, "balance for acct 5 is 600");
        allow = await proofofworktoken.allowance(accounts[0], accounts[1]);
        assert.equal(allow, 100, "Allowance shoudl be 100");
    });

    it("Total Supply", async function(){
        supply = await proofofworktoken.totalSupply();
        supply1 = supply.toNumber();
        csupply = (2**256) - 1;
        assert.equal(supply1,csupply,"Total Supply should be everything");
        contra = await proofofworktoken.balanceOf(proofofworktoken.address);
        console.log("contra",contra);
        contra1 = contra.toNumber();
        console.log("contra1",contra1);
        contrabal= 2**256 - 1000001;
        console.log("contrabal",contrabal);
        assert.equal(contra1,contrabal,"Contract balance should be total supply-1000001");

    });
});
 
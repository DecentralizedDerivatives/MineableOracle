/** This contract tests the typical workflow from the dApp 
* (user contract, cash out)
*/
var oracleToken = artifacts.require("./OracleToken.sol");
var oracleVote = artifacts.require("./OracleVote.sol");

function promisifyLogWatch(_event) {
  return new Promise((resolve, reject) => {
    _event.watch((error, log) => {
      _event.stopWatching();
      if (error !== null)
        reject(error);
      resolve(log);
    });
    });
}

contract('Base Tests', function(accounts) {
  let oracletoken;
  let oraclevote;
  let logNewValueWatcher;
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
    });
    it("getVariables", async function(){
        vars = await oracletoken.getVariables();
        assert(vars[1] == 1);
    }); 
    it("Test miner", async function () {
        console.log('START MINING RIG!!');
        logNewValueWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
    });
    it("Test Full Miner", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        assert(logMineWatcher.args._value > 0);
    });
    it("Test 10 Mines", async function () {
        for(var i = 0;i < 10;i++){
            logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
            console.log('Mining...',i);
        }
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
    it("Test Is Data", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        data = await oracletoken.isData.call(res.c[0]);
        assert(data == true);
    });
         it("Test Get Last Query", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        data = await oracletoken.getLastQuery.call();
        assert(data > 0);
    });
    it("Test Data Read", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        data = await oracletoken.retrieveData.call(res.c[0]);
        assert((data- 0) == (val- 0));
    });

      it("Test Miner Payout", async function () {
        balances = []
        for(var i = 0;i<5;i++){
            balances[i] = await oraclevote.balanceOf(accounts[i]);
        }
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        new_balances = []
        for(var i = 0;i<5;i++){
            new_balances[i] = await oraclevote.balanceOf(accounts[i]);
        }
        assert((new_balances[0] - balances[0]) == 1);
        assert((new_balances[1] - balances[1]) == 5);
        assert((new_balances[2] - balances[2]) == 10);
        assert((new_balances[3] - balances[3]) == 5);
        assert((new_balances[4] - balances[4]) == 1);
    });
    
    it("Test Add Value to Pool", async function () {
        await oracletoken.addToValuePool(22);
        balances = []
        for(var i = 0;i<5;i++){
            balances[i] = await oraclevote.balanceOf(accounts[i]);
        }
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        new_balances = []
        for(var i = 0;i<5;i++){
            new_balances[i] = await oraclevote.balanceOf(accounts[i]);
        }
        assert((new_balances[0] - balances[0]) == 1 * 2);
        assert((new_balances[1] - balances[1]) == 5* 2);
        assert((new_balances[2] - balances[2]) == 10* 2);
        assert((new_balances[3] - balances[3]) == 5* 2);
        assert((new_balances[4] - balances[4]) == 1* 2);
    });
    it("Test Difficulty Adjustment", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        vars = await oracletoken.getVariables();
        assert(vars[1] = 2);
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        vars = await oracletoken.getVariables();
        assert(vars[1] = 3);
    });
});
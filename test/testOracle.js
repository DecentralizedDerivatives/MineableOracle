/** This contract tests the typical workflow from the dApp 
* (user contract, cash out)
*/
var oracleToken = artifacts.require("OracleToken");
var oracleVote = artifacts.require("OracleVote");

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
        oracletoken = await oracleToken.new(accounts[0],22,5,[1,5,10,5,1]);
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
        await oraclevote.propAdd("testAddproposedOracle",22,5,[1,5,10,5,1], {from:accounts[8]});
        await oraclevote.vote(2, true,{from:accounts[0]} );
        let res = await oraclevote.tallyVotes(2, {from:accounts[0]} );
        res = res.logs[0].args._newOracle;
        oracletoken = await oracleToken.at(res);
    });

    it("getVariables", async function(){
        vars = await oracletoken.getVariables();
        assert(vars = ['0x0000000000000000000000000000000000000000000000000000000000000000',0]);
    }); 

    it("Test miner", async function () {
        console.log(await(oracletoken.getVariables()));
        logNewValueWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
    });
    it("Test Full Miner", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
    it("Test 10 Mines", async function () {
        console.log(await(oracletoken.getVariables()));
        for(var i = 0;i < 10;i++){
            logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
            console.log('Mining...',i);
        }
        console.log("Mined", logMineWatcher);
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
    it("Test Is Data", async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined",logMineWatcher.args._time);
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        console.log('time',res.c[0]);
        data = await oracletoken.isData(res.c[0]);
        console.log(data)
        assert(data == true);
    });
            /*
    it("Test Data Read", async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined",logMineWatcher.args._time);
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        console.log('time',res.c[0]);
        data = await oracletoken.retrieveData(res.c[0]);
        console.log(data - 0,val - 0)
        assert(data == val);
    });

            it("Test Get Last Query", async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined", logMineWatcher);
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
      it("Test Add Value to Pool", async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined", logMineWatcher);
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
     it("Test Full Miner", async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined", logMineWatcher);
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
     it("Test Difficulty Adjustment", async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined", logMineWatcher);
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
    it("Test Value Pool add, async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined", logMineWatcher);
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
      it("Test Multiple distributions", async function () {
        console.log(await(oracletoken.getVariables()));
        logMineWatcher = await promisifyLogWatch(oracletoken.Mine({ fromBlock: 'latest' }));//or Event Mine?
        console.log("Mined", logMineWatcher);
        res = logMineWatcher.args._value;
        assert(res > 0);
    });*/
});
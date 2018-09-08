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
        console.log('Oracle Token Address: ',oracletoken.address);
        oraclevote = await oracleVote.new(22,1,1);
        await oraclevote.propDudOracle(oracletoken.address);
        await oraclevote.vote(1, true,{from:accounts[0]} );
        await oraclevote.tallyVotes(1, {from:accounts[0]} )
        console.log("setDudOracle", await oraclevote.dud_Oracle.call());
        balance0 = await (oraclevote.balanceOf(accounts[0],{from:accounts[0]}));
        await oraclevote.transfer(accounts[4],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[5],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[6],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[7],100,{from:accounts[0]});
        await oraclevote.transfer(accounts[8],100,{from:accounts[0]});

        await oraclevote.propAdd("testAddproposedOracle",22,5,[1,5,10,5,1], {from:accounts[8]});
        await oraclevote.vote(2, true,{from:accounts[0]} );
        let res = await oraclevote.tallyVotes(2, {from:accounts[0]} );
        res = res.logs[0].args._newOracle;
        console.log("res address", res);
        oracletoken = await oracleToken.at(res);
    });

    it("getVariables", async function(){
        vars = await oracletoken.getVariables();
        console.log(vars);
        assert(vars = ['0x0000000000000000000000000000000000000000000000000000000000000000',0]);
    }); 

    it("Recording values to fx proof of work-no mining", async function () {
        console.log(await(oracletoken.getVariables()));
        logNewValueWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        console.log("logNewValueWatcher", logNewValueWatcher);
        // let result = await oracletoken.proofOfWork("1534377600", 5, {from: accounts[8]});
        // console.log(_result);
        // result1 = result.logs[0].args;//New value event has 5 events
        // result2 = result.logs[11].args._time; //PushValue- has 5 events Mine event-timestamp
        // await oracletoken.isData(1534377600); //assert = true
        // await oracletoken.retrieveData(1534377600);//where to get timestamp assert=5
    });

/*    it("testAdd", async function(){
        await oracletoken.testAdd(1531008000,100);
        let data = await oracletoken.retrieveData(1531008000); 
        assert(data = 100 , "data=100");
    });

    it("Sample Mine Token", async function(){

    });

    it("Mine tokens and get 20 values", async function(){
    
    });*/

/*    it("proofOfWork", async function(){
        balance3 = await (oracletoken.balanceOf(accounts[3]));
        balance4 = await (oracletoken.balanceOf(accounts[4]));
        balance5 = await (oracletoken.balanceOf(accounts[5]));
        balance6 = await (oracletoken.balanceOf(accounts[6]));
        console.log("1 proof of work");
        await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
        await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
        await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
        await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
        let res = await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
        res = res.logs[0].args;
        res = res.logs[6].args._time; 
        console.log(res);
        let data = await oracletoken.retrieveData(res); 
        assert(data = 100 , "data=100");
        balance2x = await (oracletoken.balanceOf(accounts[0]));
        console.log(balance2x);
        console.log("2 proof of work");

   await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("3");
    await oracletoken.proofOfWork(1531005120, 101, {from: accounts[3]});
     console.log("4");
    await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("5");
    await oracletoken.proofOfWork(1531005180, 102, {from: accounts[4]});
     console.log("6");
    await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("7");
    await oracletoken.proofOfWork(1531005240, 103, {from: accounts[5]});
     console.log("8");
    await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("9");
   await oracletoken.proofOfWork(1531005300, 105, {from: accounts[6]});
    balance2x = await (oracletoken.balanceOf(accounts[2]));
    balance3x = await (oracletoken.balanceOf(accounts[3]));
    balance4x = await (oracletoken.balanceOf(accounts[4]));
    balance5x = await (oracletoken.balanceOf(accounts[5]));
    balance6x = await (oracletoken.balanceOf(accounts[6]));
    assert.equal(balance2-balance2x, 1, "balance should be one for acct2");
   assert.equal(balance6-balance6x, 1, "balance should be one for acct6");
    assert.equal(balance3-balance3x, 5, "balance should be 5 for acct3");
    assert.equal(balance5-balance5x, 5, "balance should be 5 for acct5");
    assert.equal(balance3-balance3x, 10, "balance should be one for acct3");

   });  */
});
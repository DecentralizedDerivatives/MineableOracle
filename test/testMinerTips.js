/** 
* This contract tests the typical workflow for the MinerTips 
*/
/* var oracleToken = artifacts.require("./OracleToken.sol");
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

contract('Mining Tests', function(accounts) {
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
        console.log("Acct0 bal",await oraclevote.balanceOf(accounts[0]));
    });

    it("Test tip for specific timestamp", async function () {
        var currentTime = new Date() ;
        var _date = currentTime.setDate(currentTime.getDate());
        var d = (_date - (_date % 86400000))/1000;
        console.log("value pool sender begbal",await oraclevote.balanceOf(accounts[0]));
        await oracletoken.addTimeTip(22,d);
        console.log("value pool sender endbal",await oraclevote.balanceOf(accounts[0]));
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

        it("Test tip for specific timestamp", async function () {
        var currentTime = new Date() ;
        var _date = currentTime.setDate(currentTime.getDate());
        var d = (_date - (_date % 86400000))/1000;
        console.log("value pool sender begbal",await oraclevote.balanceOf(accounts[4]));
        await oracletoken.addTimeTip(22,d, {from:accounts[4]});
        console.log("value pool sender endbal afer addTimeTip",await oraclevote.balanceOf(accounts[4]));
        await oracletoken.retreiveTipIfNoValue(d, {from:accounts[4]});
        console.log("value pool sender endbal",await oraclevote.balanceOf(accounts[4]));
    }); */
/** This contract tests the typical workflow from the dApp 
* (user contract, cash out)
*/

var BigNumber = require('bignumber.js');


var oracleToken = artifacts.require("./OracleToken.sol");
var proofOfWorkToken = artifacts.require("ProofOfWorkToken.sol");

var timeframe = (86400); //Daily
var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';


const jsonrpc = '2.0'
const id = 0
const send = (method, params = []) => web3.currentProvider.send({ id, jsonrpc, method, params })

const timeTravel = async seconds => {
  await send('evm_increaseTime', [seconds])
  await send('evm_mine')
}


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
  let proofofworktoken;
  let logNewValueWatcher;


    beforeEach('Setup contract for each test', async function () {
        oracletoken = await oracleToken.new(accounts[0],1e18,(86400/60)/6,[1e18,5e18,10e18,5e18,1e18]);
        proofofworktoken = await proofOfWorkToken.new(oracletoken.address);
        balance0 = await (proofofworktoken.balanceOf(accounts[0],{from:accounts[0]}));
        await proofofworktoken.transfer(accounts[4],2e18,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[5],2e18,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[6],2e18,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[7],2e18,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[8],2e18,{from:accounts[0]});
        let res = await proofofworktoken.deployNewOracle(api,1e18,timeframe,[1e18,5e18,10e18,5e18,1e18], {from:accounts[0]});
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
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        assert(logMineWatcher.args._value > 0);
    });


    it("Test Total Supply Increase", async function () {
        initTotalSupply = await proofofworktoken.totalSupply();
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        newTotalSupply = await proofofworktoken.totalSupply();
        payout = await oracletoken.payoutTotal.call();
        console.log("payout", payout);
        console.log('Init Supply', initTotalSupply);
        console.log('NewTotal Supply', newTotalSupply);
        console.log("diff", newTotalSupply - initTotalSupply);
/*        newTotal = web3.toWei(newTotalSupply, 'ether');
        initTotal = web3.toWei(initTotalSupply, 'ether');
        payoutet = web3.toWei(payout, 'ether');
        console.log("newTotal", newTotal);
        console.log("initTotal", initTotal);
        console.log("payoutet:", payoutet);
        console.log(newTotal-initTotal);
        newTotalN = newTotalSupply.toNumber();
        initTotalN = initTotalSupply.toNumber();
        payoutetN = payout.toNumber();
        console.log("newTotalN", newTotalN);
        console.log("initTotalN", initTotalN);
        console.log("payoutetN", payoutetN);
        console.log(newTotalN-initTotalN);
        newTotalB = newTotalSupply.BigNumber();
        initTotalB = initTotalSupply.BigNumber();
        payoutetB = payout.BigNumber();
        console.log("newTotalB", newTotalB);
        console.log("initTotalB", initTotalB);
        console.log("payoutetB", payoutetB);
        console.log(newTotalB-initTotalB);*/
        //assert.deepEqual(newTotalSupply - initTotalSupply == payout);
        //assert.deepEqual((newTotal - initTotal) == payout);
    });


    it("Test 10 Mines", async function () {
        for(var i = 0;i < 10;i++){
            logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
            console.log('Mining...',i);
        }
        res = logMineWatcher.args._value;
        assert(res > 0);
    });
    it("Test Is Data", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        data = await oracletoken.isData.call(res.c[0]);
        assert(data == true);
    });
   it("Test Get Last Query", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        data = await oracletoken.getLastQuery.call();
        assert(data > 0);
    });
    
    it("Test Data Read", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;      
        begbal_sender =await proofofworktoken.balanceOf(accounts[4]);
        data = await oracletoken.retrieveData(res.c[0], {from:accounts[4]});
        resValue = data.logs[0].args._value;
        resSender = data.logs[0].args._sender;
        assert((resValue- 0) == (val- 0));
        endbal_sender =await proofofworktoken.balanceOf(accounts[4]);
        assert(begbal_sender - endbal_sender == web3.toWei(1, 'ether'));
    });

      it("Test Miner Payout", async function () {
        balances = []
        for(var i = 0;i<6;i++){
            balances[i] = await proofofworktoken.balanceOf(accounts[i]);
        }
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        new_balances = []
        for(var i = 0;i<6;i++){
            new_balances[i] = await proofofworktoken.balanceOf(accounts[i]);
        }
        assert((new_balances[5] - balances[5]) == web3.toWei(1, 'ether'));
        assert((new_balances[1] - balances[1]) == web3.toWei(5, 'ether'));
        assert((new_balances[2] - balances[2]) ==web3.toWei(10, 'ether'));
        assert((new_balances[3] - balances[3]) == web3.toWei(5, 'ether'));
        assert((new_balances[4] - balances[4]) == web3.toWei(1, 'ether'));
    });
    
    it("Test Difficulty Adjustment", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        vars = await oracletoken.getVariables();
        assert(vars[1] = 2);
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        vars = await oracletoken.getVariables();
        assert(vars[1] = 3);
    });

    it("Test didMine ", async function () {
        vars = await oracletoken.getVariables();
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        didMine = oracletoken.didMine(vars[0],accounts[1]);
        assert(didMine);
    });
     it("Test Get MinersbyValue ", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        miners = await oracletoken.getMinersByValue(res);
        assert(miners = [accounts[4],accounts[3],accounts[2],accounts[1],accounts[5]])
    });
    it("Test Add Value to Pool", async function () {
        res2 = await oracletoken.addToValuePool(5,0,{from:accounts[4]});
        resValue = res2.logs[0].args._value;
        resTime = res2.logs[0].args._time;
        let valuePool = await oracletoken.getValuePoolAt(resTime.c[0]);
        assert(valuePool == 5, "assert the value pool now has 5");//why did you have 22e18      
        balances = [];
        for(var i = 0;i<6;i++){
            balances[i] = await proofofworktoken.balanceOf(accounts[i]);
            //console.log(i, balances[i]);
        }
        await timeTravel(86400 * 10);
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        new_balances = [];
        for(var i = 0;i<6;i++){
            new_balances[i] = await proofofworktoken.balanceOf(accounts[i]);
            //console.log(i, new_balances[i]);
        }
        assert((new_balances[5] - balances[5]) == web3.toWei(1, 'ether'));
        assert((new_balances[1] - balances[1]) == web3.toWei(5, 'ether'));
        assert((new_balances[2] - balances[2]) == web3.toWei(10, 'ether'));
        assert((new_balances[3] - balances[3]) == web3.toWei(5, 'ether'));
        assert((new_balances[4] - balances[4]) == web3.toWei(1, 'ether'));
    });
    it("Test Retrieve payout pool", async function () {
        await proofofworktoken.transfer(accounts[9],23e18,{from:accounts[0]});
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;      
        totalvp = await oracletoken.getValuePoolAt(res.c[0]);    
        for(i=0;i<22;i++){
             res2 = await oracletoken.retrieveData(res.c[0], {from:accounts[9]});
             totalvp2 = await oracletoken.getValuePoolAt(res.c[0]);
        }
        totalvp3 = await oracletoken.getValuePoolAt(res.c[0]);
        balance1 = await proofofworktoken.balanceOf(accounts[9]);
        balance2 = await proofofworktoken.balanceOf(accounts[2]);
        await oracletoken.retrievePayoutPool(res.c[0]);     
        balance22 = await proofofworktoken.balanceOf(accounts[2]);
        assert(balance22-balance2 == web3.toWei(10, 'ether'));
    });

    it("Test UpdatePayoutTotal", async function () {
       payoutTotal = await oracletoken.miningMultiplier.call();
       val = await web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       await timeTravel(86400 * 366)
       await oracletoken.updatePayoutTotal();
       payoutTotal = await oracletoken.miningMultiplier.call();
       val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 4 /5)
       await timeTravel(86400 * 366)
       await oracletoken.updatePayoutTotal();
       payoutTotal = await oracletoken.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 3 /5)
       await timeTravel(86400 * 366)
       await oracletoken.updatePayoutTotal();
       payoutTotal = await oracletoken.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 2 /5)
       await timeTravel(86400 * 366)
       await oracletoken.updatePayoutTotal();
       payoutTotal = await oracletoken.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 1 /5)
       await timeTravel(86400 * 366)
       await oracletoken.updatePayoutTotal();
        payoutTotal = await oracletoken.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 0)
    });
    
});
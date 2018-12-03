/** This contract tests the typical workflow from the dApp 
* (user contract, cash out)
*/
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
        await proofofworktoken.transfer(accounts[4],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[5],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[6],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[7],100,{from:accounts[0]});
        await proofofworktoken.transfer(accounts[8],100,{from:accounts[0]});
        let res = await proofofworktoken.deployNewOracle(api,22,timeframe,[1e18,5e18,10e18,5e18,1e18], {from:accounts[0]});
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
    /*it("Test Full Miner", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        assert(logMineWatcher.args._value > 0);
    });
    it("Test Total Supply Increase", async function () {
        initTotalSupply = await proofofworktoken.totalSupply();
               logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        newTotalSupply = await proofofworktoken.totalSupply();
        payout = await oracletoken.payoutTotal.call();
        console.log('Total Supply Test', newTotalSupply,initTotalSupply,payout);
        assert(newTotalSupply - initTotalSupply == payout);
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
        console.log("begbal sender",await proofofworktoken.balanceOf(accounts[0])); 
        data = await oracletoken.retrieveData.call(res.c[0], {from:accounts[0]});
        console.log("retreived", data);
        assert((data- 0) == (val- 0));
        console.log("endbal sender",await proofofworktoken.balanceOf(accounts[0]));
    });

      it("Test Miner Payout", async function () {
        balances = []
        for(var i = 0;i<5;i++){
            balances[i] = await proofofworktoken.balanceOf(accounts[i]);
        }
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        new_balances = []
        for(var i = 0;i<5;i++){
            new_balances[i] = await proofofworktoken.balanceOf(accounts[i]);
        }
        assert((new_balances[0] - balances[0]) == web3.toWei(1, 'ether'));
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
        assert(miners = [accounts[4],accounts[3],accounts[2],accounts[1],accounts[0]])
    });*/
    it("Test Add Value to Pool", async function () {
        console.log("value pool sender begbal",await proofofworktoken.balanceOf(accounts[0]));
        await oracletoken.addToValuePool(5,0,{from:accounts[0]});
        valuePool = await oracletoken.getValuePoolAt(0);
        console.log('vap',valuePool)
        console.log('pt',await oracletoken.payoutTotal.call())
        assert(valuePool == 22e18);
        console.log("value pool sender endbal",await proofofworktoken.balanceOf(accounts[0]));
        balances = []
        for(var i = 0;i<5;i++){
            balances[i] = await proofofworktoken.balanceOf(accounts[i]);
        }
        await timeTravel(86400 * 10)
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        /*(new_balances = []
        for(var i = 0;i<5;i++){
            new_balances[i] = await proofofworktoken.balanceOf(accounts[i]);
            console.log(i);
        }
        assert((new_balances[0] - balances[0]) == web3.toWei(2, 'ether'));
        assert((new_balances[1] - balances[1]) == web3.toWei(10, 'ether'));
        assert((new_balances[2] - balances[2]) == web3.toWei(20, 'ether'));
        assert((new_balances[3] - balances[3]) == web3.toWei(10, 'ether'));
        assert((new_balances[4] - balances[4]) == web3.toWei(2, 'ether'));*/
    });
         it("Test Retrieve payout pool", async function () {
        logMineWatcher = await promisifyLogWatch(oracletoken.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;      
        console.log('res',res);
        console.log("begbal sender",await proofofworktoken.balanceOf(accounts[0])); 
        for(i=0;i<22;i++){
             await oracletoken.retrieveData.call(res.c[0], {from:accounts[0]});
        }
        balance1 = await proofofworktoken.balanceOf(accounts[2]);
        await oracletoken.retrievePayoutPool(res); 
        balance2 = await proofofworktoken.balanceOf(accounts[2]);
        console.log(balance1,balance2,web3.toWei(10, 'ether'))
        assert(balance1-balance2 == web3.toWei(10, 'ether'));
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
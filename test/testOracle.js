/** 
* This tests the oracle functions, including mining.
*/
const Web3 = require("web3"); // import web3 v1.0 constructor
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:9545"));
const BN = web3.utils.BN;

const Oracle = artifacts.require("./Oracle.sol"); // globally injected artifacts helper
var oracleAbi = Oracle.abi;
var oracleByte = Oracle.bytecode;

//var reader = artifacts.require("Reader.sol");

//var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';
var minimumStake = 1e18;

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

async function expectThrow(promise){
  try {
    await promise;
  } catch (error) {
    // TODO: Check jump destination to destinguish between a throw
    //       and an actual invalid jump.
    const invalidOpcode = error.message.search('invalid opcode') >= 0;
    // TODO: When we contract A calls contract B, and B throws, instead
    //       of an 'invalid jump', we get an 'out of gas' error. How do
    //       we distinguish this from an actual out of gas event? (The
    //       testrpc log actually show an 'invalid jump' event.)
    const outOfGas = error.message.search('out of gas') >= 0;
    const revert = error.message.search('revert') >= 0;
    assert(
      invalidOpcode || outOfGas || revert,
      'Expected throw, got \'' + error + '\' instead',
    );
    return;
  }
  assert.fail('Expected throw not received');
};

contract('Mining Tests', function(accounts) {
  let oracle;
  let owner;

    beforeEach('Setup contract for each test', async function () {
        //readcontract = await reader.new();
        owner = accounts[0];
        console.log("owner set");
        oracle = await Oracle.new(600);
        //var oracle = await new web3.eth.Contract(oracleAbi, oracle.address);
        console.log("oracle");
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[2],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[3],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[4],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[5],tokens,{from:accounts[0]});
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        await oracle.depositStake(minimumStake.toString(),{from:accounts[2]}); 
        await oracle.depositStake(minimumStake.toString(),{from:accounts[3]}); 
        await oracle.depositStake(minimumStake.toString(),{from:accounts[4]}); 
        await oracle.depositStake(minimumStake.toString(),{from:accounts[5]});

    });

    it("getVariables", async function(){
        vars = await oracle.getVariables();
        console.log(vars);
        assert(vars[2] == 1);
    }); 

/****************Mining Tests*/

    it("Test miner", async function () {
        console.log('START MINING RIG!!');
        logNewValueWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
    });
/*
    it("Test Full Miner", async function () {
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        assert(logMineWatcher.args._value > 0, "The value submitted by the miner should not be zero");
    });

    it("Test Total Supply Increase", async function () {
        initTotalSupply = await oracle.totalSupply();
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        newTotalSupply = await oracle.totalSupply();
        payout = await oracle.payoutTotal.call();
        it= await web3.fromWei(initTotalSupply, 'ether').toNumber();
        ts= await web3.fromWei(newTotalSupply, 'ether').toNumber();
        pt= await web3.fromWei(payout, 'ether').toNumber();            
        assert((ts-it) == pt , "Difference should equal the payout");
    });


    it("Test 10 Mines", async function () {
        for(var i = 0;i < 10;i++){
            logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
            //console.log('Mining...',i);
        }
        res = logMineWatcher.args._value;
        assert(res > 0, "Ensure miners are working by checking the submitted value of 10 miners is not zero");
    });

    it("Test Is Data", async function () {
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        //data = await oracle.isData.call(res.c[0]);
        data = await oracle.isData(res.c[0]);
        assert(data == true, "Should be true if Data exist for that point in time");
    });

    it("Test Get Last Query", async function () {
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;
        await oracle.getLastQuery();       
        res = await oracle.getLastQuery();
        console.log("data", res.logs[0].args);
        assert(res.logs[0].args._value > 0, "Ensure data exist for the last mine value");
    });
    
    it("Test Data Read", async function () {
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;      
        begbal_sender =await oracle.balanceOf(accounts[4]);
        await oracle.requestData(res.c[0],accounts[4], {from:accounts[4]});
        data = await oracle.retrieveData(res.c[0], {from:accounts[4]});
        resValue = data.logs[0].args._value;
        resSender = data.logs[0].args._sender;
        assert((resValue- 0) == (val- 0));
        endbal_sender =await oracle.balanceOf(accounts[4]);
        assert(begbal_sender - endbal_sender == web3.toWei(1, 'ether'), "Should be equal to fee per read");
        assert(begbal_sender - endbal_sender == readFee, "Should be equal to readfee per read");
    });

   it("Test Miner Payout", async function () {
        balances = []
        for(var i = 0;i<6;i++){
            balances[i] = await oracle.balanceOf(accounts[i]);
        }
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        new_balances = []
        for(var i = 0;i<6;i++){
            new_balances[i] = await oracle.balanceOf(accounts[i]);
        }
        assert((new_balances[5] - balances[5]) == web3.toWei(1, 'ether'));
        assert((new_balances[1] - balances[1]) == web3.toWei(5, 'ether'));
        assert((new_balances[2] - balances[2]) ==web3.toWei(10, 'ether'));
        assert((new_balances[3] - balances[3]) == web3.toWei(5, 'ether'));
        assert((new_balances[4] - balances[4]) == web3.toWei(1, 'ether'));
    });
    
    it("Test Difficulty Adjustment", async function () {
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        vars = await oracle.getVariables();
        assert(vars[1] = 2);
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        vars = await oracle.getVariables();
        assert(vars[1] = 3);
    });

    it("Test didMine ", async function () {
        vars = await oracle.getVariables();
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        didMine = oracle.didMine(vars[0],accounts[1]);
        assert(didMine);
    });

     it("Test Get MinersbyValue ", async function () {
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        miners = await oracle.getMinersByValue(res);
        assert(miners = [accounts[4],accounts[3],accounts[2],accounts[1],accounts[5]])
    });




    it("Test UpdatePayoutTotal", async function () {
       payoutTotal = await oracle.miningMultiplier.call();
       val = await web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       await timeTravel(86400 * 366)
       await oracle.updatePayoutTotal();
       payoutTotal = await oracle.miningMultiplier.call();
       val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 4 /5, "Miner reward should decrease 1/5 after year=1")
       await timeTravel(86400 * 366)
       await oracle.updatePayoutTotal();
       payoutTotal = await oracle.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 3 /5, "Miner reward should decrease 1/5 from year1 to year2")
       await timeTravel(86400 * 366)
       await oracle.updatePayoutTotal();
       payoutTotal = await oracle.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 2 /5, "Miner reward should decrease 1/5 from year2 to year3")
       await timeTravel(86400 * 366)
       await oracle.updatePayoutTotal();
       payoutTotal = await oracle.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 1 * 1 /5, "Miner reward should decrease 1/5 from year4 to year5")
       await timeTravel(86400 * 366)
       await oracle.updatePayoutTotal();
        payoutTotal = await oracle.miningMultiplier.call();
        val = web3.fromWei(payoutTotal.toNumber(), "ether" ) 
       assert(val == 0, "Miner reward should be zero after year 5")
    });

    it("Test contract read no tokens", async function(){
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;      
        balance = await oracle.balanceOf(readcontract.address);
        await expectThrow(readcontract.getLastValue(oracle.address));
        balance1 = await oracle.balanceOf(readcontract.address);
    });

    it("Test read request data", async function(){
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        res = logMineWatcher.args._time;  
        await oracle.requestData(res.c[0],accounts[4], {from:accounts[4]});
        info = await oracle.getRequest(res.c[0],accounts[4])
        assert(info.toNumber() > 0, "request should work")
    }); 
    it("Test dev Share", async function(){
        begbal = await oracle.balanceOf(accounts[0]);
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        endbal = await oracle.balanceOf(accounts[0]);
        devshare = await oracle.devShare.call();
        payout = await oracle.payoutTotal.call();
        console.log('payoutdev',(endbal - begbal),payout.toNumber(),devshare.toNumber())
        assert((endbal - begbal)/1e18  - (payout.toNumber() * devshare.toNumber())/1e18 < .1, "devShare")
    }); 
    */
    
});
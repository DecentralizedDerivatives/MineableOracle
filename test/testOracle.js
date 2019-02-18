/** 
* This tests the oracle functions, including mining.
*/
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));
const BN = require('bn.js');
const helper = require("./helpers/test_helpers");

const Oracle = artifacts.require("./Oracle.sol"); // globally injected artifacts helper
var Reader = artifacts.require("Reader.sol");
var oracleAbi = Oracle.abi;
var oracleByte = Oracle.bytecode;

var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';

function promisifyLogWatch(_contract,_event) {
  return new Promise((resolve, reject) => {
    web3.eth.subscribe('logs', {
      address: _contract.options.address,
      topics:  ['0xc12a8e1d75371aee68708dbc301ab95ef7a6022cd0eda54f8669aafcb77d21bd']
    }, (error, result) => {
        console.log('Result',result);
        console.log('Error',error);
        if (error)
          reject(error);
        web3.eth.clearSubscriptions();
        resolve(result);
    })
    .on("data", (log) => {
    console.log(log);
    })
    .on("changed", (log) => {
    console.log(log);
   })

  });
}

/*function promisifyLogWatch(_contract,_event) {
  return new Promise((resolve, reject) => {
    web3.eth.subscribe('logs', {
      address: _contract.options.address,
      topics:  ['0x62ca650db86f0a3c5182ae2d9536edbaa54d4603ddf88e0385ed28915a7d2535']
    }, (error, result) => {
        console.log('Result',result);
        console.log('Error',error);
        if (error)
          reject(error);
        web3.eth.clearSubscriptions();
        resolve(result);
    })
    .on("data", (log) => {
    console.log(log);
    })
    .on("changed", (log) => {
    console.log(log);
   })

  });
}*/


contract('Mining Tests', function(accounts) {
  let oracle;
  let oracle2;
  let owner;
  let reader;
  let logNewValueWatcher;
  let logMineWatcher;

    beforeEach('Setup contract for each test', async function () {
        owner = accounts[0];
        oracle = await Oracle.new();
        oracle2 = await new web3.eth.Contract(oracleAbi,oracle.address);
        console.log('Oracle Address ',oracle.address);
        var tokens = await web3.utils.toWei('2', 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[2],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[3],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[4],tokens,{from:accounts[0]});
        await oracle.transfer(accounts[5],tokens,{from:accounts[0]});
        await oracle.depositStake({from:accounts[1]}); 
        await oracle.depositStake({from:accounts[2]}); 
        await oracle.depositStake({from:accounts[3]}); 
        await oracle.depositStake({from:accounts[4]}); 
        await oracle.depositStake({from:accounts[5]});
        await oracle.requestData(api,1);
    });

    it("getStakersCount", async function(){
        let count = await oracle.getStakersCount({from:accounts[1]});
        assert(web3.utils.hexToNumberString(count)==5, "count is 5");
    });

    it("getStakersInfo", async function(){
        let info = await oracle.getStakerInfo(accounts[1]);
        let stake = web3.utils.hexToNumberString(info['0']);
        let state = web3.utils.hexToNumberString(info['1']);
        let index = web3.utils.hexToNumberString(info['2']);
        console.log("stake, state, index", stake, state, index);
        let today = new Date()
        let today2 = today - (today % 86400);
        console.log("today", today, today2)
    });
    

    it("getVariables", async function(){
        var vars = await oracle.getVariables();
        console.log(vars);
        let miningApiId = web3.utils.hexToNumberString(vars['1']);
        let difficulty = web3.utils.hexToNumberString(vars['2']);
        let sapi = vars['3'];
        console.log("miningApiId, difficulty, sapi", miningApiId, difficulty, sapi);
        assert(miningApiId == 1, "miningApiId should be 1");
        assert(difficulty == 1, "Difficulty should be 1");
        assert.equal(sapi,api, "sapi = api");
    }); 
/****************Mining Tests******************/
      it("Test miner", async function () {
        console.log('START MINING RIG!!');
        var val = await oracle.getVariables();
        await promisifyLogWatch(oracle2, 'NewValue');
   });
//pass
//https://web3js.readthedocs.io/en/1.0/web3-eth-abi.html#decodelog
//https://codeburst.io/deep-dive-into-ethereum-logs-a8d2047c7371
    it("Test Full Miner", async function () {
        console.log("newvalue sha3------",web3.eth.utils.sha3('NewValue(uint,uint,uint)'));
        console.log("newvalue solidity sha3------",web3.eth.utils.soliditySha3('NewValue(uint,uint,uint)'));
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        console.log("logoutput DATA------",logMineWatcher.data);
        //types = [i['type'] for i in e['inputs']]['uint', 'uint', 'uint'];
        //names = [i['name'] for i in e['inputs']]['_apiId','_time','_value'];
/*        values =  eth_abi.decode_abi(['uint', 'uint', 'uint'], logMineWatcher['data']);
        dict(zip(['_apiId','_time','_value'], values));
        console.log("dictzip", dict(zip(['_apiId','_time','_value'], values)));*/
        console.log('testing log stuff');
        testing2 = await web3.eth.abi.decodeLog(['uint', 'uint', 'uint'],logMineWatcher['data'],'0xc12a8e1d75371aee68708dbc301ab95ef7a6022cd0eda54f8669aafcb77d21bd');
        console.log('testing2', testing2);
        testing = await web3.eth.abi.decodeParameters(['uint', 'uint', 'uint'], web3.utils.hexToNumberString(logMineWatcher.data));
        console.log('testing', testing);
        //console.log("value", logMineWatcher.args[0]._value);
        //assert(logMineWatcher.args[1]._value > 0, "The value submitted by the miner should not be zero");
    });
//pass
  it("Test Total Supply Increase", async function () {
        initTotalSupply = await oracle.totalSupply();
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        newTotalSupply = await oracle.totalSupply();
        payout = await oracle.payoutTotal.call();
        it= await web3.utils.fromWei(initTotalSupply, 'ether');
        console.log('it',it);
        ts= await web3.utils.fromWei(newTotalSupply, 'ether');
        console.log("ts", ts);
        pt= await web3.utils.fromWei(payout, 'ether');            
        assert((ts-it) == pt , "Difference should equal the payout");
    });

/*
    it("Test 10 Mines", async function () {
        for(var i = 0;i < 10;i++){
            logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
            //console.log('Mining...',i);
        }
        res = logMineWatcher.args._value;
        assert(res > 0, "Ensure miners are working by checking the submitted value of 10 miners is not zero");
    });

    it("Test Is Data", async function () {
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;       
        //data = await oracle.isData.call(res.c[0]);
        data = await oracle.isData(res.c[0]);
        assert(data == true, "Should be true if Data exist for that point in time");
    });

    it("Test Get Last Query", async function () {
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;
        await oracle.getLastQuery();       
        res = await oracle.getLastQuery();
        console.log("data", res.logs[0].args);
        assert(res.logs[0].args._value > 0, "Ensure data exist for the last mine value");
    });
    
    it("Test Data Read", async function () {
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
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

//pass
   it("Test Miner Payout", async function () {
        balances = []
        for(var i = 0;i<6;i++){
            balances[i] = await oracle.balanceOf(accounts[i]);
            console.log("balance",i, web3.utils.hexToNumberString(balances[i]));
        }
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        new_balances = []
        for(var i = 0;i<6;i++){
            new_balances[i] = await oracle.balanceOf(accounts[i]);
            console.log("new balance",i, web3.utils.hexToNumberString(new_balances[i]));
        }
        assert((web3.utils.hexToNumberString(new_balances[5]) - web3.utils.hexToNumberString(balances[5])) == web3.utils.toWei('1', 'ether'));
        assert((web3.utils.hexToNumberString(new_balances[1]) - web3.utils.hexToNumberString(balances[1])) == web3.utils.toWei('5', 'ether'));
        assert((web3.utils.hexToNumberString(new_balances[2]) - web3.utils.hexToNumberString(balances[2])) == web3.utils.toWei('10', 'ether'));
        assert((web3.utils.hexToNumberString(new_balances[3]) - web3.utils.hexToNumberString(balances[3])) == web3.utils.toWei('5', 'ether'));
        assert((web3.utils.hexToNumberString(new_balances[4]) - web3.utils.hexToNumberString(balances[4])) == web3.utils.toWei('1', 'ether'));
        //assert((web3.utils.hexToNumberString(new_balances[4]) - web3.utils.hexToNumberString(balances[4])) == web3.utils.toWei('1.1', 'ether'));
    });
    
   it("Test Difficulty Adjustment", async function () {
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        vars = await oracle.getVariables();
        console.log("vars1", vars);
        assert(vars[2] = 2);//difficulty not changing.....
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        vars = await oracle.getVariables();
        console.log("vars2", vars);
        assert(vars[2] = 3);
    });*/
//pass
    it("Test didMine ", async function () {
        vars = await oracle.getVariables();
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        didMine = oracle.didMine(vars[0],accounts[1]);
        assert(didMine);
    });

/*     it("Test Get MinersbyValue ", async function () {
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        ///get the timestamp from the emit newValue log...
        res = logMineWatcher.args._time;
        console.log("res",res);
        miners = await oracle.getMinersByValue(1, res);
        assert(miners = [accounts[4],accounts[3],accounts[2],accounts[1],accounts[5]])
    });*/

/*

    it("Test contract read no tokens", async function(){
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        res = logMineWatcher.args._time;
        val = logMineWatcher.args._value;      
        balance = await oracle.balanceOf(readcontract.address);
        await helper.expectThrow(readcontract.getLastValue(oracle.address));
        balance1 = await oracle.balanceOf(readcontract.address);
    });

    it("Test read request data", async function(){
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        res = logMineWatcher.args._time;  
        await oracle.requestData(res.c[0],accounts[4], {from:accounts[4]});
        info = await oracle.getRequest(res.c[0],accounts[4])
        assert(info.toNumber() > 0, "request should work")
    }); 
    it("Test dev Share", async function(){
        begbal = await oracle.balanceOf(accounts[0]);
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        endbal = await oracle.balanceOf(accounts[0]);
        devshare = await oracle.devShare.call();
        payout = await oracle.payoutTotal.call();
        console.log('payoutdev',(endbal - begbal),payout.toNumber(),devshare.toNumber())
        assert((endbal - begbal)/1e18  - (payout.toNumber() * devshare.toNumber())/1e18 < .1, "devShare")
    }); 
    
    it("Test miner, alternating api request on Q and auto select", async function () {
        await oracle.requestData(api,1);
        await oracle.requestData(api2,10);
        await oracle.requestData(api,11);
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        //console.log("value", logMineWatcher.args[0]._value);
        //console.log("value", logMineWatcher.args[0]._time);
        //console.log("value", logMineWatcher.args[0]._apiId);
        //assert(logMineWatcher.args[1]._value > 0, "The value submitted by the miner should not be zero");
        await oracle.requestData(api2,15);
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        //console.log("value", logMineWatcher.args[0]._value);
        //console.log("value", logMineWatcher.args[0]._time);
        //console.log("value", logMineWatcher.args[0]._apiId);
        //assert(logMineWatcher.args[1]._value > 0, "The value submitted by the miner should not be zero");
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        //console.log("value", logMineWatcher.args[0]._value);
        //console.log("value", logMineWatcher.args[0]._time);
        //console.log("value", logMineWatcher.args[0]._apiId);
        //assert(logMineWatcher.args[1]._value > 0, "The value submitted by the miner should not be zero");
    });

    it("Test dispute", async function () {
        balance1 = await (oracle.balanceOf(accounts[2],{from:accounts[4]}));
        //request two apis
        await oracle.requestData(api,1);
        await oracle.requestData(api2,10);
        await oracle.requestData(api,11);

        //mine and record for api request
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        _timestamp = web3.utils.hexToNumberString(logMineWatcher.args[0]._time);
        //console.log("value", logMineWatcher.args[0]._value);
        //console.log("value", logMineWatcher.args[0]._time);
        //console.log("value", logMineWatcher.args[0]._apiId);
        //assert(logMineWatcher.args[1]._value > 0, "The value submitted by the miner should not be zero");
        
        //mine and record for api2 request
        await oracle.requestData(api2,15);
        await helper.advanceTime(10 * 1);
        logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        //console.log("value", logMineWatcher.args[0]._value);
        _timestamp2 = web3.utils.hexToNumberString(logMineWatcher.args[0]._time);
        _apiId2 = web3.utils.hexToNumberString(logMineWatcher.args[0]._apiId);
        //console.log("value", logMineWatcher.args[0]._time);
        //console.log("value", logMineWatcher.args[0]._apiId);
        //assert(logMineWatcher.args[1]._value > 0, "The value submitted by the miner should not be zero");
        apid2value = await oracle.retrieveData(_apiId2, _timestamp2);
        console.log("apid2value", apid2value);
        await helper.advanceTime(30 * 1);

        //getApiForTime
        apiidt1 = await oracle.getApiForTime(_timestamp);
        assert(apiidt1 == 1, "should be 1");
        apiidt2 = await oracle.getApiForTime(_timestamp2);
        assert(apiidt2 == _apiId2, "should be 2 or apiid2");
        blocknum = awaot oracle.getMinedBlockNum(_apiId2, _timestamp2);

        //intiate dispute on api2
        await oracle.initDispute(_apiId2, _timestamp2, {from:accounts[5]});
        count = await oracle.countDisputes();
        console.log('dispute count:', web3.utils.hexToNumberString(count));
        await oracle.vote(_apiId2, true, {from:accounts[5]});
        await helper.timeTravel(86400 * 8);
        await oracle.tallyVotes(_apiId2);
        dispInfo = await oracle.getDisputeInfo(_apiId2);
        console.log("dispInfo", dispInfo);
        voted = await.didVote(1, accounts[0]);
        assert(voted == true, "account 0 voted");
        voted = await.didVote(1, accounts[5]);
        assert(voted == false, "account 5 did not vote");
        alldisp = await oracle.getDisputesIds();
        console.log("alldisp", alldisp);
        apid2valueF = await oracle.retrieveData(_apiId2, _timestamp2);
        console.log("apid2value", apid2valueF);
        assert(apid2valueF == 0 ,"value should now be zero this checks updateDisputeValue-internal fx  works");
        balance2 = await (oracle.balanceOf(accounts[2],{from:accounts[4]}));
    });
    */
});